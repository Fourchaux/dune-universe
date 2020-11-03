(*
 * A pid Registry that can be used to spawn a type-safe
 * where_is function within a module. This is mostly just sugar over the Erlang
 * FFI module to tag the return values in a more idiomatic OCaml way.
 *
 * Unfortunately using any typed value as a name means that we
 * don't have enough information to constrain the type of the
 * messages that the registered pid can use.
 *
 * Fortunately, we can keep the names private (unexported),
 * making it impossible for anyone to access them.
 *
 * This means that a module M using this interface, can use an internal,
 * unexported polymorphic variant tag to register itself, and provide an
 * implementation of `where_is` that'll give back the appropriately typed Pid
 * if there is one.
 *
 *)

let where_is : 'a -> 'message Erlang.pid option =
 fun name ->
  let pid = Erlang.where_is name in
  let is_pid = Erlang.is_pid pid in
  match is_pid with true -> Some pid | _ -> None

let register :
    'a -> 'message Erlang.pid -> ('message Erlang.pid, string) result =
 fun name pid ->
  match where_is name with
  | Some _ -> Error "pid already registered"
  | None -> (
      match Erlang.register name pid with
      | true -> Ok pid
      | false -> Error "could not register pid" )
