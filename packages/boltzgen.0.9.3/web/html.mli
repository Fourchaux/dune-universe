(******************************************************************************)
(* Copyright (c) 2016 DooMeeR                                                 *)
(*                                                                            *)
(* Permission is hereby granted, free of charge, to any person obtaining      *)
(* a copy of this software and associated documentation files (the            *)
(* "Software"), to deal in the Software without restriction, including        *)
(* without limitation the rights to use, copy, modify, merge, publish,        *)
(* distribute, sublicense, and/or sell copies of the Software, and to         *)
(* permit persons to whom the Software is furnished to do so, subject to      *)
(* the following conditions:                                                  *)
(*                                                                            *)
(* The above copyright notice and this permission notice shall be             *)
(* included in all copies or substantial portions of the Software.            *)
(*                                                                            *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,            *)
(* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF         *)
(* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                      *)
(* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE     *)
(* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     *)
(* OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION      *)
(* WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.            *)
(******************************************************************************)

(** Simple interface to create HTML entities using js_of_ocaml. *)

type t

val alert: string -> unit

val get_by_id: ?on_change: (string -> unit) -> string -> t
val get_by_id': ?on_change: (string -> unit) -> string -> t * (t list -> unit)
val get_value_by_id : string -> unit -> string

val br: unit -> t
val hi: int -> string -> t
val text: string -> t
val text': string -> t * (string -> unit)
val img: ?class_: string -> ?alt: string -> ?title: string -> string -> t
val a:
  ?class_: string -> ?href: string -> ?title: string -> ?on_click: (unit -> unit) -> t list -> t
val kbd' : string -> t * (string -> unit)
val button: ?class_: string -> ?on_click: (unit -> unit) -> t list -> t
val p: ?class_: string -> t list -> t
val p_text: ?class_: string -> string -> t
val p': ?class_: string -> t list -> t * (t list -> unit)
val div: ?class_: string -> ?title:string -> ?id:string -> t list -> t
val div': ?class_: string -> ?title:string -> ?id:string -> t list -> t * (t list -> unit)
val span: ?class_: string -> t list -> t
val span': ?class_: string -> t list -> t * (t list -> unit)
val checkbox_input: ?class_: string -> ?on_change: (bool -> unit) -> bool -> t
val checkbox_input':
  ?class_: string -> ?on_change: (bool -> unit) -> bool -> t * (bool -> unit)
val radio_input:
  ?class_: string -> ?on_change: (bool -> unit) -> ?name: string -> bool -> t
val radio_input':
  ?class_: string -> ?on_change: (bool -> unit) -> ?name: string ->
  bool -> t * (bool -> unit)
val text_input: ?class_: string -> ?on_change: (string -> unit) -> ?_type : string -> string -> t
val text_input':
  ?class_: string -> ?on_change: (string -> unit) -> ?_type : string -> string ->
  t * (string -> unit)

val select:
  ?class_: string -> ?on_change: (string -> unit) -> string list ->
  t


val text_area: ?class_: string -> ?on_change: (string -> unit) -> ?is_read_only:bool -> string -> t
val text_area':
  ?class_: string -> ?on_change: (string -> unit) -> ?is_read_only:bool -> string ->
  t * (string -> unit)


val run: (unit -> t) -> unit

val get_hash: unit -> string
val set_hash: string -> unit
val on_hash_change: (unit -> unit) -> unit
