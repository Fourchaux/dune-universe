open Rresult

val ignore_dirs : string list
val compile : string list -> string list -> bool -> Mirage_key.mode -> (unit, [> R.msg ]) result
val build : Functoria.Info.t -> (unit, [> R.msg ]) result
