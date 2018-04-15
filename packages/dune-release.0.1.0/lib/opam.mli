(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   dune-release 0.1.0
  ---------------------------------------------------------------------------*)

(** opam helpers. *)

open Bos_setup

(** {1:cmd Command} *)

val cmd : Cmd.t
(** [cmd] is a command for [opam]. *)

(** {1:publish Publish} *)

val ensure_publish : unit -> (unit, R.msg) result
(** [ensure_publish ()] makes sure [opam-publish] is in the executable
    search PATH. *)

val submit : ?msg:string -> pkg_dir:Fpath.t -> (unit, R.msg) result
(** [submit ~pkg_dir] submits the package [pkg_dir] with [opam-publish]
    and submission message [msg] (if any) to the OCaml opam repository. *)

(** {1:pkgs Packages} *)

val ocaml_base_packages : String.set
(** [ocaml_base_packages] are the base opam packages distributed
    with OCaml: ["base-bigarray"], ["base-bytes"], ["base-threads"],
    ["base-unix"]. *)

(** {1:file Files} *)

(** opam files *)
module File : sig

  (** {1:file opam file} *)

  val field_names : String.set
  (** [field_names] is the maximal domain of the map returned by
      {!fields}, excluding extension fields (not yet supported by
      [opam-lib] 1.2.2). *)

  val fields : Fpath.t -> ((string list) String.map , R.msg) result
  (** [fields f] returns a simplified model of the fields of the opam
      file [f]. The domain of the result is included in
      {!field_names}. Note that the [depends:] and [depopts:] fields
      are returned without version constraints. *)

  (** {1:deps Dependencies} *)

  val deps : ?opts:bool -> (string list) String.map -> String.set
  (** [deps ~opts fields] returns the packages mentioned in the [depends:]
      fields, if [opts] is [true] (default) those from [depopts:] are added
      aswell. *)
end

(** [descr] files. *)
module Descr : sig

  (** {1:descr Descr file} *)

  type t = string * string
  (** The type for opam [descr] files, the package synopsis and the
      description. *)

  val of_string : string -> (t, R.msg) result
  (** [of_string s] is a description from the string [s]. *)

  val to_string : t -> string
  (** [to_string d] is [d] as a string. *)

  val of_readme :
    ?flavour:Text.flavour -> string -> (t, R.msg) result
  (** [of_readme r] extracts an opam description file from a readme [r]
      with a certain structure. *)

  val of_readme_file : Fpath.t -> (t, R.msg) result
  (** [of_readme_file f] extracts an opam description file from
      a readme file [f] using {!Text.flavour_of_fpath} and
      {!of_readme}. *)
end

(** [url] files. *)
module Url : sig

  (** {1:url Url file} *)

  val v : uri:string -> checksum:string -> string
  (** [v ~uri ~checksum] is an URL file for URI [uri] with
      checksum [checksum]. *)

  val with_distrib_file : uri:string -> Fpath.t -> (string, R.msg) result
  (** [with_distrib_file ~uri f] is an URL file for URI [uri] with
      the checksum of file [f]. *)
end

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
