(** Helpers for using {!Capnp_rpc_lwt} on traditional operating systems. *)

open Capnp_rpc_lwt

module Listen_address : sig
  type t = [
    | `Unix of string
  ]

  val conv : t Cmdliner.Arg.conv
  (** A cmdliner argument converter for [t]. *)

  val pp : t Fmt.t
end

module Connect_address : sig
  type t = [
    | `Unix of string
  ]

  val conv : t Cmdliner.Arg.conv
  (** A cmdliner argument converter for [t]. *)

  val pp : t Fmt.t
end

val endpoint_of_socket : switch:Lwt_switch.t -> Lwt_unix.file_descr -> Capnp_rpc_lwt.Endpoint.t
(** [endpoint_of_socket ~switch fd] is an endpoint that sends and receives on [fd].
    When [switch] is turned off, [fd] is closed. *)

val serve : ?backlog:int -> ?offer:'a Capability.t -> Listen_address.t -> 'b Lwt.t
(** [serve ~offer address] listens for new connections on [address] and handles them.
    Clients can get access to the bootstrap object [offer].
    [backlog] is passed to [Unix.listen]. *)

val connect : ?switch:Lwt_switch.t -> ?offer:'a Capability.t -> Connect_address.t -> 'b Capability.t
(** [connect addr] connects to the server at [addr] and returns its bootstrap object.
    If [offer] is given, the client will also offer this service to the remote vat.
    If [switch] is given then turning it off will disconnect,
    and disconnecting will turn off the switch. *)
