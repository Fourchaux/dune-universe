val map_fst : ('a -> 'b) -> ('a * 'c) -> ('b * 'c)
val map_snd : ('a -> 'b) -> ('c * 'a) -> ('c * 'b)

module Stdlib : sig
  val map_fst : ('a -> 'b) -> ('a * 'c) -> ('b * 'c)
  val map_snd : ('a -> 'b) -> ('c * 'a) -> ('c * 'b)
end

