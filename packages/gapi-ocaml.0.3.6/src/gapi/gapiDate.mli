(** Datetime data type.
  *)

type t = Netdate.t

val epoch : Netdate.t

val now : unit -> Netdate.t

val to_string : ?time:bool -> t -> string

val of_string : string -> t

