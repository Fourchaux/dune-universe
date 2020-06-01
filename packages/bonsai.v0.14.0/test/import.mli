open! Core_kernel
open! Import

module Event : sig
  type t = private
    | Packed : 'a * 'a Type_equal.Id.t -> t
    | External_event : string -> t
    | No_op : t
    | Sequence : t list -> t

  val pack : 'a Type_equal.Id.t -> 'a -> t
  val sequence : t list -> t
  val no_op : t
  val external_ : string -> t
end

module Incr : Incremental.S
module Bonsai_lib = Bonsai
module Bonsai : Bonsai.S with module Incr = Incr with module Event = Event

module Incr_map :
  Incr_map.S with type state_witness := Incr.state_witness and module Incr := Incr

include module type of struct
  include Expect_test_helpers_core
end
