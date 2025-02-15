open Apron

type t = Interval.t = {mutable inf: Scalar.t; mutable sup: Scalar.t}

(** APRON Intervals on scalars *)

val of_scalar : Scalar.t -> Scalar.t -> t
(** Build an interval from a lower and an upper bound *)

val of_infsup : Scalar.t -> Scalar.t -> t
(** depreciated *)

val of_mpq : Mpq.t -> Mpq.t -> t

val of_mpqf : Mpqf.t -> Mpqf.t -> t

val of_int : int -> int -> t

val of_frac : int -> int -> int -> int -> t

val of_float : float -> float -> t

val of_mpfr : Mpfr.t -> Mpfr.t -> t
(** Create an interval from resp. two

    - multi-precision rationals [Mpq.t]
    - multi-precision rationals [Mpqf.t]
    - integers
    - fractions [x/y] and [z/w]
    - machine floats
    - Mpfr floats *)

val is_top : t -> bool
(** Does the interval represent the universe ([\[-oo,+oo\]]) ? *)

val is_bottom : t -> bool
(** Does the interval contain no value ([\[a,b\]] with a>b) ? *)

val is_leq : t -> t -> bool
(** Inclusion test. [is_leq x y] returns [true] if [x] is included in [y] *)

val cmp : t -> t -> int
(** Non Total Comparison: 0: equality -1: i1 included in i2 +1: i2 included in
    i1 -2: i1.inf less than or equal to i2.inf +2: i1.inf greater than i2.inf *)

val equal : t -> t -> bool
(** Equality test *)

val is_zero : t -> bool
(** Is the interval equal to [0,0] ? *)

val equal_int : t -> int -> bool
(** Is the interval equal to [i,i] ? *)

val neg : t -> t
(** Negation *)

val top : t

val bottom : t
(** Top and bottom intervals (using [DOUBLE] coefficients) *)

val set_infsup : t -> Scalar.t -> Scalar.t -> unit
(** Fill the interval with the given lower and upper bouunds *)

val set_top : t -> unit

val set_bottom : t -> unit
(** Fill the interval with top (resp. bottom) value *)

val print : Format.formatter -> t -> unit
(** Print an interval, under the format [\[inf,sup\]] *)

(** {1 Extensions} *)

val join : t -> t -> t
(** [join a b] computes the smallest interval [c] such that
    [is_leq
     a c && is_leq b c]*)

val to_float : t -> float * float

val to_mpqf : t -> Mpqf.t * Mpqf.t

val range : t -> Scalar.t
(** scalar range of an interval *)

val range_mpqf : t -> Mpqf.t
(** same as range but result as an mpqf *)

val mid : t -> Scalar.t
(** midpoint of an interval *)

val spawn : t -> Mpqf.t
(** Random uniform value within an interval, according to the type *)

val is_bounded : t -> bool
(** returns true if and only if both bounds are finite *)
