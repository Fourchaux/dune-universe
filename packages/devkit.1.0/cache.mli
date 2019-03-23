(** Various types of in-memory caches *)

module type Lock = sig
  type t
  val create : unit -> t
  val locked : t -> (unit -> 'a) -> 'a
end

(** see also {!ExtThread.LockMutex} *)
module NoLock : Lock

module TimeLimited2(E : Set.OrderedType)(Lock : Lock) : sig
  type t
  type time = int64
  val create : Time.t -> t
  val add : t -> E.t -> unit
  val get : t -> E.t -> (E.t * time) option
  val count : t -> int
  val iter : t -> (E.t -> unit) -> unit
end

module LRU(K : Hashtbl.HashedType) : sig
  type 'v t
  val create : int -> 'v t
  val put : 'v t -> K.t -> 'v -> unit
  val put_evicted : 'v t -> K.t -> 'v -> (K.t * 'v) option
  val get : 'v t -> K.t -> 'v
  val get_evicted : 'v t -> K.t -> ('v * (K.t * 'v) option)
  val find : 'v t -> K.t -> 'v
  val replace : 'v t -> K.t -> 'v -> unit
  val remove : 'v t -> K.t -> unit
  val miss : 'v t -> int
  val hit : 'v t -> int
  val mem : 'v t -> K.t -> bool
  val size : 'v t -> int
  val iter : (K.t -> 'v -> unit) -> 'v t -> unit
  val lru_free : 'v t -> int
  val lfu_free : 'v t -> int
end

(** Count elements *)
module Count : sig
  type 'a t
  val create : unit -> 'a t
  val of_list : ('a * int) list -> 'a t
  val of_enum : ('a * int) Enum.t -> 'a t
  val clear : 'a t -> unit
  val add : 'a t -> 'a -> unit
  val plus : 'a t -> 'a -> int -> unit
  val del : 'a t -> 'a -> unit
  val minus : 'a t -> 'a -> int -> unit
  val enum : 'a t -> ('a * int) Enum.t
  val iter : 'a t -> ('a -> int -> unit) -> unit
  val fold : 'a t -> ('a -> int -> 'b -> 'b) -> 'b -> 'b

  (** number of times given element was seen *)
  val count : 'a t -> 'a -> int
  val count_all : 'a t -> int

  (** number of distinct elements *)
  val size : 'a t -> int
  val show : 'a t -> ?sep:string -> ('a -> string) -> string
  val show_sorted : 'a t -> ?limit:int -> ?sep:string -> ('a -> string) -> string
  val stats : 'a t -> ?cmp:('a -> 'a -> int) -> ('a -> string) -> string
  val report : 'a t -> ?limit:int -> ?cmp:('a -> 'a -> int) -> ?sep:string -> ('a -> string) -> string
  val distrib : float t -> float array
  val show_distrib : ?sep:string -> float t -> string
  val names : 'a t -> 'a list
end

module Group : sig
  type ('a,'b) t
  val by : ('a -> 'b) -> ('a,'b) t
  val add : ('a,'b) t -> 'a -> unit
  val get : ('a,'b) t -> 'b -> 'a list
  val iter : ('a,'b) t -> ('b -> 'a list -> unit) -> unit
  val keys : ('a,'b) t -> 'b Enum.t
end

val group_fst : ('a * 'b) Enum.t -> ('a * 'b list) Enum.t

(** One-to-one associations *)
module Assoc : sig
  type ('a,'b) t
  val create : unit -> ('a,'b) t

  (** Add association, assert on duplicate key *)
  val add : ('a,'b) t -> 'a -> 'b -> unit

  (** Get associated value, @raise Not_found if key is not present *)
  val get : ('a,'b) t -> 'a -> 'b

  (** Get associated value *)
  val try_get : ('a,'b) t -> 'a -> 'b option

  (** Delete association, assert if key is not present, @return associated value *)
  val del : ('a,'b) t -> 'a -> 'b

  (** Delete association, assert if key is not present *)
  val remove : ('a,'b) t -> 'a -> unit
  val size : ('a,'b) t -> int

  val fold: ('a -> 'b -> 'c -> 'c) -> ('a, 'b) t -> 'c -> 'c
end

module Lists : sig
  type ('a,'b) t
  val create : unit -> ('a,'b) t
  val add : ('a,'b) t -> 'a -> 'b -> unit
  val get : ('a,'b) t -> 'a -> 'b list
  val set : ('a,'b) t -> 'a -> 'b list -> unit
  val enum : ('a,'b) t -> ('a * 'b list) Enum.t
  val clear : ('a, 'b) t -> unit
  val count_keys : ('a, 'b) t -> int
  val count_all : ('a, 'b) t -> int
end

class ['a] cache : ('a list -> unit) -> limit:int ->
  object
    val mutable l : 'a list
    method add : 'a -> unit
    method clear : unit
    method dump : unit
    method get : 'a list
    method name : string
    method size : int
    method to_list : 'a list
  end

type 'a reused
val reuse : (unit -> 'a) -> ('a -> unit) -> 'a reused
val use : 'a reused -> 'a
val recycle : 'a reused -> 'a -> unit

module Reuse(T : sig type t val create : unit -> t val reset : t -> unit end) : sig
  type t = T.t
  val get : unit -> t
  val release : t -> unit
end
