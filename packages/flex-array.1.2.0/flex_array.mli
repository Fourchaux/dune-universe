(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Jean-Christophe Filliatre                               *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2.1, with the special exception on linking            *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

(** Flexible arrays.

    Flexible arrays are arrays whose size can be changed by adding or
    removing elements at either end (one at a time).

    This is an implementation of flexible arrays using Braun trees,
    following

      Rob Hoogerwoord
      A logarithmic implementation of flexible arrays
      http://alexandria.tue.nl/repository/notdare/772185.pdf

    All operations ([get], [set], [cons], [tail], [snoc], [liat])
    have logarithmic time complexity and logarithmic stack space.
*)

type +'a t
(** The type of flexible arrays.
    This is an immutable data structure.
    Values of type ['a t] can be compared using structural equality [=]
    (provided the elements of type ['a] can). *)

val empty: 'a t

val make: int -> 'a -> 'a t
(** [make n v] returns a flexible array of size [n], initialized with [v].
    All  the elements of this new array are physically equal to [v]
    (in the sense of the [==] predicate).
    Time complexity O(log n). *)

val init: int -> (int -> 'a) -> 'a t
(** [init n f] returns a flexible array of size [n], with elements
    [f 0, f 1, ..., f (n-1)]. Time complexity O(n).
    Caveat: function [f] is applied only once per index, but not
    in increasing order of indices. *)

val of_array: 'a array -> 'a t
(** [of_array a] returns a flexible array of size [List.length l],
    with the elements of [l] in order. Time complexity O(n).
    Merely a shortcut built over [init]. *)

val of_list: 'a list -> 'a t
(** [of_list l] returns a flexible array of size [List.length l],
    with the elements of [l] in order. Time complexity O(n).
    Logarithmic stack space. *)

val length: 'a t ->  int
(** Time complexity O(1). *)

val get: 'a t -> int -> 'a
(** [get a i] returns the element at index [i] in array [a].
    The first element has index 0.
    Raises [Invalid_argument] if [i] is outside the range 0
    to [length a - 1]. *)

val set: 'a t -> int -> 'a -> 'a t
(** [set a i v] returns a new array with all elements are identical to those
    of [a], except at index [i] where the element is [v].
    Raises [Invalid_argument] if [i] is outside the range 0
    to [length a - 1]. *)

val cons: 'a -> 'a t -> 'a t
(** [cons v a] returns a new array obtained by appending the value [v]
    at the front of array [a]. *)

val tail: 'a t -> 'a t
(** [tail a] returns a new array obtained by removing the value at the
    front of array [a].
    Raises [Invalid_argument] if [a] has length 0. *)

val snoc: 'a t -> 'a -> 'a t
(** [snoc v a] returns a new array obtained by appending the value [v]
    at the end of array [a]. *)

val liat: 'a t -> 'a t
(** [liat a] returns a new array obtained by removing the value at the
    end of array [a].
    Raises [Invalid_argument] if [a] has length 0. *)

(** {1 Iterators} *)

val iter: ('a -> unit) -> 'a t -> unit
(** [iter f a] applies function [f] in turn to all the elements of [a].
    It is equivalent to [f (get a 0); f (get a 1); ...;
    f (get a (n - 1); ()] where [n] is the length of the array [a],
    but runs faster.
    Time complexity O(n). Space complexity O(n). Constant stack space. *)

val iteri: (int -> 'a -> unit) -> 'a t -> unit
(** Same as {!iter}, but the
    function is applied with the index of the element as first argument,
    and the element itself as second argument. *)

val fold : ('a -> 'b -> 'a) -> 'a -> 'b t -> 'a
(** [fold f x a] computes
    [f (... (f (f x (get a 0)) (get a 1)) ...) (get a (n-1))],
    where [n] is the length of the array [a],
    but runs faster.
    Time complexity O(n). Space complexity O(n). Constant stack space. *)

val foldi : ('a -> int -> 'b -> 'a) -> 'a -> 'b t -> 'a
(** Same as {!fold}, but the
    function is applied with the index of the element as second argument. *)

val map: ('a -> 'b) -> 'a t -> 'b t
(** [map f a] returns a new flexible array with elements [f (get a 0), ...,
    f (get a (n-1)] where [n] is the length of [a].
    Time complexity O(n). Logarithmic stack space. *)

val mapi: (int -> 'a -> 'b) -> 'a t -> 'b t
(** [mapi f a] returns a new flexible array with elements [f 0 (get a 0), ...,
    f (n-1) (get a (n-1)] where [n] is the length of [a].
    Time complexity O(n). Logarithmic stack space. *)

val pp: ?pp_sep:(Format.formatter -> unit -> unit) ->
        (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a t -> unit
(** [pp ?pp_sep pp_v fmt a] prints items of flexible array [a] using [pp_v]
    to print each item, and calling [pp_sep] between items ([pp_sep] defaults
    to {!Format.pp_print_cut}. Does nothing on empty flexible arrays.)

    @since 1.2.0 *)
