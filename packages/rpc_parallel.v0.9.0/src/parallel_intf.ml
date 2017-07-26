open! Core
open! Async

(** See README for more details *)

(** A [('worker, 'query, 'response) Function.t] is a type-safe function ['query ->
    'response Deferred.t] that can only be run on a ['worker]. Under the hood it
    represents an Async Rpc protocol that we know a ['worker] will implement. *)
module type Function = sig
  type ('worker, 'query, 'response) t

  val map
    :  ('worker, 'query, 'a) t
    -> f:('a -> 'b)
    -> ('worker, 'query, 'b) t

  val contra_map
    :  ('worker, 'a, 'response) t
    -> f:('b -> 'a)
    -> ('worker, 'b, 'response) t

  (** Common functions that are implemented by all workers *)

  (** This implementation simply calls [Shutdown.shutdown 0] *)
  val shutdown  : (_, unit, unit) t

  (** This implementation will add another [Log.Output] for [Log.Global] that transfers
      log messages to the returned pipe. You can subscribe to a worker's log more than
      once and from different processes, as each call simply adds a new [Log.Output].
      Closing the pipe will remove the corresponding [Log.Output].

      NOTE: You will never get any log messages before this implementation has run (there
      is no queuing of log messages). As a consequence, you will never get any log
      messages written in a worker's init functions. *)
  val async_log : (_, unit, Log.Message.Stable.V2.t Pipe.Reader.t) t

  (** A given process can have multiple worker servers running (of the same or different
      worker types). This implementation closes the server on which it is run. All
      existing open connections will remain open, but no further connections to this
      worker server will be accepted.

      NOTE: calling [close_server] on a worker process that is only running one worker
      server will leave a stranded worker process if no other cleanup has been setup
      (e.g. setting up [on_client_disconnect] or [Connection.close_finished] handlers) *)
  val close_server : (_, unit, unit) t
end

(** A [Heartbeater.t] is an Rpc server only used for heartbeats. The only thing you can do
    with a [Heartbeater.t] is connect to it and get notified when the connection
    closed. *)
module type Heartbeater = sig
  type t [@@deriving bin_io]

  (** A helper function to be used on the [~parent_heartbeater] argument of the
      [init_worker_state] function. The suggested use is:

      Heartbeater.(if_spawned connect_and_shutdown_on_disconnect_exn) parent_heartbeater

      [if_spawned f parent_heartbeater] will run [f] on the heartbeater if this worker was
      created with [spawn]. If the worker was created with [Connection.serve] (in
      process), nothing occurs and [`No_parent] is returned. *)
  val if_spawned
    :  ( t -> ([> `No_parent ] as 'a) Deferred.t )
    -> [ `Spawned of t | `Served ]
    -> 'a Deferred.t

  (** Connect to the given [Heartbeater.t] (host and port) and call
      [Shutdown.shutdown] upon [Rpc.Connection.close_finished], raising an exception if
      unable to connect. The returned [Deferred.t] is determined once the initial
      connection has been established. *)
  val connect_and_shutdown_on_disconnect_exn : t -> [> `Connected ] Deferred.t

  val connect_and_wait_for_disconnect_exn
    :  t
    -> [> `Connected of [ `Disconnected ] Deferred.t ] Deferred.t
end

module type Worker = sig
  type ('worker, 'query, 'response) _function

  (** A [Worker.t] type is defined [with bin_io] so it is possible to create functions
      that take a worker as an argument. *)
  type t [@@deriving bin_io, sexp_of]

  (** A type alias to make the [Connection] signature more readable *)
  type worker = t

  type 'a functions

  (** Accessor for the functions implemented by this worker type *)
  val functions : t functions

  type worker_state_init_arg
  type connection_state_init_arg

  module Id : Identifiable
  val id : t -> Id.t

  (** [serve arg] will start an Rpc server in process implementing all the functions
      of the given worker. *)
  val serve
    :  ?max_message_size  : int
    -> ?handshake_timeout : Time.Span.t
    -> ?heartbeat_config  : Rpc.Connection.Heartbeat_config.t
    -> worker_state_init_arg
    -> worker Deferred.t

  module Connection : sig
    type t [@@deriving sexp_of]

    (** Run functions implemented by this worker *)
    val run
      :  t
      -> f : (worker, 'query, 'response) _function
      -> arg : 'query
      -> 'response Or_error.t Deferred.t

    val run_exn
      :  t
      -> f : (worker, 'query, 'response) _function
      -> arg : 'query
      -> 'response Deferred.t

    (** Connect to a given worker, returning a type wrapped [Rpc.Connection.t] that can be
        used to run functions. *)
    val client : worker -> connection_state_init_arg -> t Or_error.t Deferred.t
    val client_exn : worker -> connection_state_init_arg -> t Deferred.t

    (** [with_client worker init_arg f] connects to the [worker]'s server, initializes the
        connection state with [init_arg]  and runs [f] until an exception is thrown or
        until the returned Deferred is determined.

        NOTE: You should be careful when using this with [Pipe_rpc].
        See [Rpc.Connection.with_close] for more information. *)
    val with_client
      :  worker
      -> connection_state_init_arg
      -> f: (t -> 'a Deferred.t)
      -> 'a Or_error.t Deferred.t

    val close : t -> unit Deferred.t
    val close_finished : t -> unit Deferred.t
    val close_reason : t -> on_close: [`started | `finished] -> Info.t Deferred.t
    val is_closed : t -> bool
  end

  (** The various [spawn] functions create a new worker process that
      implements the functions specified in the [Worker_spec].

      [name] will be attached to certain error messages and is useful for debugging.

      [env] extends the environment of the spawned worker process.

      [connection_timeout] serves two purposes. [spawn] returns an error if the master
      hasn't gotten a register rpc from the spawned worker within [connection_timeout] or
      if a worker hasn't gotten its init_arg from the master within [connection_timeout]
      of sending the register rpc. This may need be to increased if the init arg is really
      large (serialization and deserialization takes more than [connection_timeout]).

      [cd] changes the current working directory of a spawned worker process.

      [on_failure exn] will be called in the spawning process upon the worker process
      raising a background exception. All exceptions raised before functions return will be
      returned to the caller. [on_failure] will be called in [Monitor.current ()] at the
      time of this spawn call.

      [worker_state_init_arg] (below) will be passed to [init_worker_state] of the given
      [Worker_spec] module. This initializes a persistent worker state for all connections
      to this worker. *)
  type 'a with_spawn_args
    =  ?where : Executable_location.t  (** default Local *)
    -> ?name : string
    -> ?env : (string * string) list
    -> ?connection_timeout:Time.Span.t  (** default 10 sec *)
    -> ?cd : string  (** default / *)
    -> on_failure : (Error.t -> unit)
    -> 'a

  (** The spawned worker process daemonizes. Any initialization errors that wrote to
      stderr (Rpc_parallel internal initialization, not user initialization code) will be
      captured and rewritten to the spawning process's stderr with the prefix
      "[WORKER %NAME% STDERR]".

      [redirect_stdout] and [redirect_stderr] specify stdout and stderr of the worker
      process. *)
  val spawn
    : (?umask : int  (** defaults to use existing umask *)
       -> redirect_stdout : Fd_redirection.t
       -> redirect_stderr : Fd_redirection.t
       -> worker_state_init_arg
       -> t Or_error.t Deferred.t) with_spawn_args

  (** Similar to [spawn] but make an initial connection to the spawned worker process. *)
  val spawn_and_connect
    : (?umask : int  (** defaults to use existing umask *)
       -> redirect_stdout : Fd_redirection.t
       -> redirect_stderr : Fd_redirection.t
       -> connection_state_init_arg : connection_state_init_arg
       -> worker_state_init_arg
       -> (t * Connection.t) Or_error.t Deferred.t) with_spawn_args

  (** Similar to [spawn] but the worker process does not daemonize. If the process was
      spawned on a remote host, the ssh [Process.t] is returned. *)
  val spawn_in_foreground
    : (worker_state_init_arg
       -> (t * Process.t) Or_error.t Deferred.t) with_spawn_args

  (** Matching spawn functions that raise on an error *)
  val spawn_exn
    : (?umask : int
       -> redirect_stdout : Fd_redirection.t
       -> redirect_stderr : Fd_redirection.t
       -> worker_state_init_arg
       -> t Deferred.t) with_spawn_args

  val spawn_and_connect_exn
    : (?umask : int
       -> redirect_stdout : Fd_redirection.t
       -> redirect_stderr : Fd_redirection.t
       -> connection_state_init_arg : connection_state_init_arg
       -> worker_state_init_arg
       -> (t * Connection.t) Deferred.t) with_spawn_args

  val spawn_in_foreground_exn
    : (worker_state_init_arg
       -> (t * Process.t) Deferred.t) with_spawn_args
end

module type Functions = sig
  type _heartbeater

  type worker

  type worker_state_init_arg
  type worker_state

  type connection_state_init_arg
  type connection_state

  type 'worker functions
  val functions : worker functions

  (** [init_worker_state] is called with the [init_arg] passed to [spawn] or [serve]

      If [spawn] was called, it is highly recommeded to call
      [connect_and_shutdown_on_disconnect_exn] on the supplied heartbeater of the spawner.

      The [Cleanup.connect_and_shutdown_on_disconnect_if_spawned_exn] function does just
      this for you. *)
  val init_worker_state
    :  parent_heartbeater : [ `Spawned of _heartbeater | `Served ]
    -> worker_state_init_arg
    -> worker_state Deferred.t

  (** [init_connection_state] is called with the [init_arg] passed to [Connection.client]

      [connection] should only be used to register [close_finished] callbacks, not to
      dispatch.  *)
  val init_connection_state
    :  connection   : Rpc.Connection.t
    -> worker_state : worker_state
    -> connection_state_init_arg
    -> connection_state Deferred.t
end

module type Creator = sig
  type ('worker, 'query, 'response) _function

  type worker

  type worker_state
  type connection_state

  (** [create_rpc ?name ~f ~bin_input ~bin_output ()] will create an [Rpc.Rpc.t] with
      [name] if specified and use [f] as an implementation for this Rpc. It returns back a
      [_function], a type-safe Rpc protocol. *)
  val create_rpc
    :  ?name : string
    -> f
       : (worker_state : worker_state
          -> conn_state : connection_state
          -> 'query
          -> 'response Deferred.t)
    -> bin_input : 'query Bin_prot.Type_class.t
    -> bin_output : 'response Bin_prot.Type_class.t
    -> unit
    -> (worker, 'query, 'response) _function

  (** [create_pipe ?name ~f ~bin_input ~bin_output ()] will create an [Rpc.Pipe_rpc.t]
      with [name] if specified. The implementation for this Rpc is a function that creates
      a [Pipe.Reader.t] and a [Pipe.Writer.t], then calls [f arg ~writer] and returns the
      reader.

      Notice that [aborted] is not exposed. The pipe is closed upon aborted. *)
  val create_pipe
    :  ?name : string
    -> f
       : (worker_state  : worker_state
          -> conn_state : connection_state
          -> 'query
          -> 'response Pipe.Reader.t Deferred.t)
    -> bin_input : 'query Bin_prot.Type_class.t
    -> bin_output : 'response Bin_prot.Type_class.t
    -> unit
    -> (worker, 'query, 'response Pipe.Reader.t) _function

  (** [create_one_way ?name ~f ~bin_msg ()] will create an [Rpc.One_way.t] with [name] if
      specified and use [f] as an implementation. *)
  val create_one_way
    :  ?name : string
    -> f
       : (worker_state  : worker_state
          -> conn_state : connection_state
          -> 'query
          ->  unit)
    -> bin_input : 'query Bin_prot.Type_class.t
    -> unit
    -> (worker, 'query, unit) _function

  (** [create_reverse_pipe ?name ~f ~bin_query ~bin_update ~bin_response ()] generates a
      function allowing you to send a [query] and a pipe of [update]s to a worker. The
      worker will send back a [response]. It is up to you whether to send a [response]
      before or after finishing with the pipe; Rpc_parallel doesn't care. *)
  val create_reverse_pipe
    :  ?name:string
    -> f:(worker_state  : worker_state
          -> conn_state : connection_state
          -> 'query
          -> 'update Pipe.Reader.t
          -> 'response Deferred.t)
    -> bin_query    : 'query    Bin_prot.Type_class.t
    -> bin_update   : 'update   Bin_prot.Type_class.t
    -> bin_response : 'response Bin_prot.Type_class.t
    -> unit
    -> (worker, 'query * 'update Pipe.Reader.t, 'response) _function

  (** [of_async_rpc ~f rpc] is the analog to [create_rpc] but instead of creating an Rpc
      protocol, it uses the supplied one *)
  val of_async_rpc
    :  f
       : (worker_state  : worker_state
          -> conn_state : connection_state
          -> 'query
          -> 'response Deferred.t)
    -> ('query, 'response) Rpc.Rpc.t
    -> (worker, 'query, 'response) _function

  (** [of_async_pipe_rpc ~f rpc] is the analog to [create_pipe] but instead of creating a
      Pipe rpc protocol, it uses the supplied one.

      Notice that [aborted] is not exposed. The pipe is closed upon aborted. *)
  val of_async_pipe_rpc
    :  f
       : (worker_state  : worker_state
          -> conn_state : connection_state
          -> 'query
          -> 'response Pipe.Reader.t Deferred.t)
    -> ('query, 'response, Error.t) Rpc.Pipe_rpc.t
    -> (worker, 'query, 'response Pipe.Reader.t) _function

  (** [of_async_one_way_rpc ~f rpc] is the analog to [create_one_way] but instead of
      creating a One_way rpc protocol, it uses the supplied one *)
  val of_async_one_way_rpc
    :  f
       : (worker_state  : worker_state
          -> conn_state : connection_state
          -> 'query
          -> unit)
    -> 'query Rpc.One_way.t
    -> (worker, 'query, unit) _function
end

(** Specification for the creation of a worker type *)
module type Worker_spec = sig
  type ('worker, 'query, 'response) _function
  type _heartbeater

  (** A type to encapsulate all the functions that can be run on this worker. Using a
      record type here is often the most convenient and readable. *)
  type 'worker functions

  (** State associated with each [Worker.t]. If this state is mutable, you must
      think carefully when making multiple connections to the same spawned worker. *)
  module Worker_state : sig
    type t
    type init_arg [@@deriving bin_io]
  end

  (** State associated with each connection to a [Worker.t] *)
  module Connection_state : sig
    type t
    type init_arg [@@deriving bin_io]
  end

  (** The functions that can be run on this worker type *)
  module Functions
      (C : Creator
       with type worker_state            = Worker_state.t
        and type connection_state        = Connection_state.t
        and type ('w, 'q, 'r) _function := ('w, 'q, 'r) _function)
    : Functions
      with type worker                    := C.worker
       and type 'a functions              := 'a functions
       and type worker_state              := Worker_state.t
       and type worker_state_init_arg     := Worker_state.init_arg
       and type connection_state          := Connection_state.t
       and type connection_state_init_arg := Connection_state.init_arg
       and type _heartbeater              := _heartbeater
end

module type Parallel = sig
  module Function    : Function
  module Heartbeater : Heartbeater

  module type Worker = Worker
    with type ('w, 'q, 'r) _function := ('w, 'q, 'r) Function.t

  module type Functions = Functions
    with type _heartbeater := Heartbeater.t

  module type Creator = Creator
    with type ('w, 'q, 'r) _function := ('w, 'q, 'r) Function.t

  module type Worker_spec = Worker_spec
    with type ('w, 'q, 'r) _function := ('w, 'q, 'r) Function.t
     and type _heartbeater           := Heartbeater.t

  (** module Worker = Make(T)

      The [Worker] module has specialized functions to spawn workers and run functions on
      workers. *)
  module Make (S : Worker_spec) : Worker
    with type 'a functions              := 'a S.functions
     and type worker_state_init_arg     := S.Worker_state.init_arg
     and type connection_state_init_arg := S.Connection_state.init_arg

  (** [start_app command] should be called from the top-level in order to start the parallel
      application. This function will parse certain environment variables and determine
      whether to start as a master or a worker.

      [rpc_max_message_size], [rpc_handshake_timeout], [rpc_heartbeat_config] can be used
      to alter the rpc defaults. These rpc settings will be used for all connections.
      This can be useful if you have long async jobs. *)
  val start_app
    :  ?rpc_max_message_size : int
    -> ?rpc_handshake_timeout : Time.Span.t
    -> ?rpc_heartbeat_config : Rpc.Connection.Heartbeat_config.t
    -> Command.t
    -> unit

  (** Use [State.get] to query whether the current process has been initialized as an rpc
      parallel master ([start_app] or [init_master_exn] has been called). We return a
      [State.t] rather than a [bool] so that you can require evidence at the type level.
      If you want to certify, as a precondition, for some function that [start_app] was
      used, require a [State.t] as an argument. If you don't need the [State.t] anymore,
      just pattern match on it. *)
  module State : sig
    type t = private [< `started ]

    val get : unit -> t option
  end

  (** If you want more direct control over your executable, you can use the [Expert] module
      instead of [start_app]. If you use [Expert], you are responsible for starting the
      master and worker rpc servers. [worker_command_args] will be the arguments sent to
      each spawned worker. Running your executable with these args must follow a code path
      that calls [worker_init_before_async_exn] and then [start_worker_server_exn]. *)
  module Expert : sig
    (** [start_master_server_exn] must be called in the single master process. It is
        necessary to be able to spawn workers. Raises if the process was spawned. *)
    val start_master_server_exn
      :  ?rpc_max_message_size  : int
      -> ?rpc_handshake_timeout : Time.Span.t
      -> ?rpc_heartbeat_config : Rpc.Connection.Heartbeat_config.t
      -> worker_command_args : string list
      -> unit
      -> unit

    module Worker_env : sig
      type t
    end

    (** [worker_init_before_async_exn] must be called in a spawned worker process before the
        async scheduler has started. You must not read from stdin before this function call.

        This has the side effect of calling [chdir]. *)
    val worker_init_before_async_exn : unit -> Worker_env.t

    (** [start_worker_server_exn] must be called in each spawned process. It is illegal to
        call both [start_master_server_exn] and [start_worker_server_exn] in the same
        process. Raises if the process was not spawned.

        This has the side effect of scheduling a job that completes the daemonization of
        this process (if the process should daemonize). This includes redirecting stdout and
        stderr according to [redirect_stdout] and [redirect_stderr]. All writes to stdout
        before this job runs are blackholed. All writes to stderr before this job runs are
        redirected to the spawning process's stderr. *)
    val start_worker_server_exn : Worker_env.t -> unit
  end
end
