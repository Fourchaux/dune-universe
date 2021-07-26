(* This file is part of asak.
 *
 * Copyright (C) 2019 IRIF / OCaml Software Foundation.
 *
 * asak is distributed under the terms of the MIT license. See the
 * included LICENSE file for details. *)

open Wtree

module Distance : sig

  type t = Regular of int | Infinity

  val compare : t -> t -> int
  val lt : t -> t -> bool
  val max : t -> t -> t
  val min : t -> t -> t

end

module Hash :
  sig
    type t = Lambda_hash.fingerprint
    val compare : t -> t -> int
  end

module HMap : Map.S with type key = Hash.t

(** Create initial clusters, grouping labels by fingerprint. *)
val initial_cluster : ('a * Lambda_hash.fingerprint) list -> 'a list HMap.t

(** Given a list of AST hashes (identified by a key), perform a kind of complete-linkage
    clustering using a particular semimetric.

    @param filter_small_trees If specified, will remove hashes
    that do not have at least this weight.

    @return A list of trees, where
    two keys are in the same tree only if they share at least one hash and in
    the same leaf if they share exactly the same hash list.

    The list is sorted with biggest trees first.
 *)
val cluster :
  ?filter_small_trees:int
  -> ('a * Lambda_hash.hash) list -> ('a list) wtree list

(** Print recursively a cluster given a printer for the labels. *)
val print_cluster : ('a -> string) -> ('a list) wtree list -> unit
