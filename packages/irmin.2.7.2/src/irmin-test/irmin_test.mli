module type S =
  Irmin.S
    with type step = string
     and type key = string list
     and type contents = string
     and type branch = string

module type LAYERED_STORE =
  Irmin_layers.S
    with type step = string
     and type key = string list
     and type contents = string
     and type branch = string

val reporter : ?prefix:string -> unit -> Logs.reporter

type t = {
  name : string;
  init : unit -> unit Lwt.t;
  clean : unit -> unit Lwt.t;
  config : Irmin.config;
  store : (module S);
  layered_store : (module LAYERED_STORE) option;
  stats : (unit -> int * int) option;
}

val line : string -> unit
val store : (module Irmin.S_MAKER) -> (module Irmin.Metadata.S) -> (module S)

val layered_store :
  (module Irmin_layers.Maker) ->
  (module Irmin.Metadata.S) ->
  (module LAYERED_STORE)

val testable : 'a Irmin.Type.t -> 'a Alcotest.testable
val check : 'a Irmin.Type.t -> string -> 'a -> 'a -> unit
val checks : 'a Irmin.Type.t -> string -> 'a list -> 'a list -> unit

module Store : sig
  val run :
    string ->
    ?slow:bool ->
    misc:unit Alcotest.test list ->
    (Alcotest.speed_level * t) list ->
    unit
end
