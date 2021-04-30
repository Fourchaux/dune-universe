(*
 * Copyright (c) 2021 Craig Ferguson <craig@tarides.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open! Import
open S.Store_properties

module type S = sig
  module Hash : Hash.S
  (** Internal hashes. *)

  module Contents : Contents.STORE with type key = Hash.t
  (** Private content store. *)

  module Node : Node.STORE with type key = Hash.t
  (** Private node store. *)

  module Commit : Commit.STORE with type key = Hash.t
  (** Private commit store. *)

  module Branch : Branch.STORE with type value = Hash.t
  (** Private branch store. *)

  (** Private slices. *)
  module Slice :
    Slice.S
      with type contents = Contents.key * Contents.value
       and type node = Node.key * Node.value
       and type commit = Commit.key * Commit.value

  (** Private repositories. *)
  module Repo : sig
    type t

    include OF_CONFIG with type _ t := t
    (** @inline *)

    include CLOSEABLE with type _ t := t
    (** @inline *)

    val contents_t : t -> read Contents.t
    val node_t : t -> read Node.t
    val commit_t : t -> read Commit.t
    val branch_t : t -> Branch.t

    val batch :
      t ->
      (read_write Contents.t ->
      read_write Node.t ->
      read_write Commit.t ->
      'a Lwt.t) ->
      'a Lwt.t
  end

  (** URI-based low-level sync. *)
  module Sync : sig
    include Sync.S with type commit = Commit.key and type branch = Branch.key

    val v : Repo.t -> t Lwt.t
  end
end
