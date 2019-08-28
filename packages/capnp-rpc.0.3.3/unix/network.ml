module Log = Capnp_rpc.Debug.Log
module Tls_wrapper = Capnp_rpc_lwt.Tls_wrapper.Make(Unix_flow)

module Location = struct
  include Capnp_rpc_lwt.Capnp_address.Location

  let abs_path p =
    if Filename.is_relative p then
      Filename.concat (Sys.getcwd ()) p
    else p

  let validate_public = function
    | `Unix path -> if Filename.is_relative path then Fmt.failwith "Path %S is relative!" path
    | `TCP _ -> ()

  let unix x = `Unix (abs_path x)
  let tcp ~host ~port = `TCP (host, port)
end

module Address
  : Capnp_rpc_lwt.S.ADDRESS with type t = Location.t * Capnp_rpc_lwt.Auth.Digest.t
  = Capnp_rpc_lwt.Capnp_address

module Types = struct
  type provision_id
  type recipient_id
  type third_party_cap_id = [`Two_party_only]
  type join_key_part
end

type t = unit

let error fmt =
  fmt |> Fmt.kstrf @@ fun msg ->
  Error (`Msg msg)

let parse_third_party_cap_id _ = `Two_party_only

let addr_of_host host =
  match Unix.gethostbyname host with
  | exception Not_found ->
    Capnp_rpc.Debug.failf "Unknown host %S" host
  | addr ->
    if Array.length addr.Unix.h_addr_list = 0 then
      Capnp_rpc.Debug.failf "No addresses found for host name %S" host
    else
      addr.Unix.h_addr_list.(0)

let connect_socket = function
  | `Unix path ->
    Logs.info (fun f -> f "Connecting to %S..." path);
    let socket = Unix.(socket PF_UNIX SOCK_STREAM 0) in
    Unix.connect socket (Unix.ADDR_UNIX path);
    socket
  | `TCP (host, port) ->
    Logs.info (fun f -> f "Connecting to %s:%d..." host port);
    let socket = Unix.(socket PF_INET SOCK_STREAM 0) in
    Unix.connect socket (Unix.ADDR_INET (addr_of_host host, port));
    socket

let connect () ~switch ~secret_key (addr, auth) =
  match connect_socket addr with
  | exception ex ->
    Lwt.return @@ error "@[<v2>Network connection for %a failed:@,%a@]" Location.pp addr Fmt.exn ex
  | socket ->
    let flow = Unix_flow.connect ~switch (Lwt_unix.of_unix_file_descr socket) in
    Tls_wrapper.connect_as_client ~switch flow secret_key auth

let accept_connection ~switch ~secret_key flow =
  Tls_wrapper.connect_as_server ~switch flow secret_key
