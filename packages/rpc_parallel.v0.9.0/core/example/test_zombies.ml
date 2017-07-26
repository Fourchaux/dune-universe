open Core
open Async
open Rpc_parallel_core_deprecated.Std

(* A simple use of the [Rpc_parallel_core] library. Spawn long-running workers and
   perform process management *)

let worker_main =
  function
  | false -> return ()
  | true ->
    (Clock.after (sec 0.5)
     >>> fun () -> failwith "Zombie apocalypse"
    );
    return ()

module Parallel_app = Parallel_deprecated.Make(struct
  type worker_arg = bool [@@deriving bin_io]
  type worker_ret = unit [@@deriving bin_io]
  let worker_main = worker_main
end)

let handle_error worker err =
  Log.Global.error "Worker process %s failed: %s" worker (Error.to_string_hum err)

let rec run_worker_in_loop ~where () =
  Parallel_app.spawn_worker_exn ~where
    ~redirect_stdout:`Dev_null
    ~redirect_stderr:`Dev_null
    true
    ~on_failure:(handle_error "test worker")
  >>= fun ((), _worker_id) ->
  Core.Printf.printf "Worker spawned\n%!";
  Clock.after (sec 1.)
  >>= fun () -> run_worker_in_loop ~where ()

let run_worker ~where () =
  Parallel_app.spawn_worker_exn ~where
    ~redirect_stdout:`Dev_null
    ~redirect_stderr:`Dev_null
    false
    ~on_failure:(handle_error "test worker")
  >>= fun ((), worker_id) ->
  Core.Printf.printf "Worker spawned\n%!";

  Core.Printf.printf "Going to shutdown worker in 5s...\n%!";
  Clock.after (sec 5.)
  >>= fun () ->
  Core.Printf.printf "Initiating worker shutdown\n%!";
  Parallel_app.kill_worker worker_id
  >>= fun result ->
  Or_error.ok_exn result;
  Core.Printf.printf "Worker shutdown complete, exiting.\n%!";
  return ()

let command =
  Command.async ~summary:"Test binary to check proper process management"
    Command.Spec.(
      empty
      +> flag "on" (optional string)
           ~doc:"host Run worker on this host instead of locally"
      +> flag "die" no_arg
           ~doc:" Run an exception-throwing worker in a loop"
    )
    (fun on die () ->
       (match on with
        | None -> return (Ok `Local)
        | Some host ->
          Parallel_deprecated.Remote_executable.copy_to_host
            ~executable_dir:"/tmp"
            host
          >>=? fun re ->
          return (Ok (`Remote re))
       )
       >>= function
       | Error e ->
         Log.Global.error "Failed to copy executable: %s"
           (Error.to_string_hum e);
         return ()
       | Ok where ->
         if die then begin
           don't_wait_for (run_worker_in_loop ~where ());
           (Clock.after (sec 25.)
            >>> fun () -> Pervasives.exit 0
           );
           Deferred.never ()
         end
         else
           run_worker ~where ()
    )

let () = Parallel_app.run command
