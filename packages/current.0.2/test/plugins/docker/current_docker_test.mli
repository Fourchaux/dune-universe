(* Some dummy build primitives. *)

type source = Fpath.t

module Image : sig type t end

val build : ?on:string -> source Current.t -> Image.t Current.t
(** [build ~on:platform src] builds a Docker image from source. *)

val run : Image.t Current.t -> cmd:string list -> unit Current.t
(** [run image ~cmd] runs [cmd] in Docker image [image]. *)

val complete : string -> cmd:string list -> (unit, [`Msg of string]) result -> unit
(** Marks a previous [run] as complete. *)

val push : Image.t Current.t -> tag:string -> unit Current.t
(** [push x ~tag] publishes [x] on Docker Hub as [tag]. *)

val reset : unit -> unit
(** Reset state for tests. *)

val assert_finished : unit -> unit
(** Check all containers are stopped. *)
