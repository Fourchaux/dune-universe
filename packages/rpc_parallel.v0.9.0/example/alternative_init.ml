open Core
open Async

module Worker = struct
  module T = struct
    type 'worker functions = unit

    module Worker_state = struct
      type init_arg = unit [@@deriving bin_io]
      type t = unit
    end

    module Connection_state = struct
      type init_arg = unit [@@deriving bin_io]
      type t = unit
    end

    module Functions
        (C : Rpc_parallel.Creator
         with type worker_state := Worker_state.t
          and type connection_state := Connection_state.t) = struct
      let functions = ()

      let init_worker_state ~parent_heartbeater () =
        Rpc_parallel.Heartbeater.(if_spawned connect_and_shutdown_on_disconnect_exn)
          parent_heartbeater
        >>| fun ( `Connected | `No_parent ) -> ()

      let init_connection_state ~connection:_ ~worker_state:_ = return
    end
  end
  include Rpc_parallel.Make(T)
end

let worker_command =
  let open Command.Let_syntax in
  Command.Staged.async'
    ~summary:"for internal use"
    [%map_open
      let () = return ()
      in
      fun () ->
        let worker_env = Rpc_parallel.Expert.worker_init_before_async_exn () in
        stage (fun `Scheduler_started ->
          Rpc_parallel.Expert.start_worker_server_exn worker_env;
          Deferred.never ())
    ]

let main_command =
  let open Command.Let_syntax in
  Command.async'
    ~summary:"start the master and spawn a worker"
    [%map_open
      let () = return ()
      in
      fun () ->
        Rpc_parallel.Expert.start_master_server_exn ~worker_command_args:["worker"] ();
        Worker.spawn_and_connect_exn ~on_failure:Error.raise
          ~redirect_stdout:`Dev_null ~redirect_stderr:`Dev_null
          ~connection_state_init_arg:() ()
        >>| fun (_worker, _connection) ->
        printf "Success.\n"
    ]

let command =
  Command.group
    ~summary:"Using Rpc_parallel.Expert"
    [ "worker", worker_command
    ; "main", main_command
    ]

let () = Command.run command
