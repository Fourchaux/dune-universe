(*
 * Copyright (c) 2011-2012 Anil Madhavapeddy <anil@recoil.org>
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

open Bigarray_compat

type t = (char, int8_unsigned_elt, c_layout) Array1.t

type buf = Cstruct.t

let page_size = 1 lsl 12
let page_alignment = 4096

let length t = Array1.dim t

external alloc_pages: bool -> int -> t = "caml_mirage_iopage_alloc_pages"

external c_get_addr : t -> nativeint = "caml_mirage_iopage_get_addr"

let get_addr t = c_get_addr t

let get_page t = Nativeint.(div (get_addr t) (of_int page_size))

let get n =
  if n < 0
  then raise (Invalid_argument "Io_page.get cannot allocate a -ve number of pages")
  else if n = 0
  then Array1.create char c_layout 0
  else (
    try alloc_pages false n with Out_of_memory ->
    Gc.compact ();
    alloc_pages true n
  )

let get_order order = get (1 lsl order)

let to_pages t =
  assert(length t mod page_size = 0);
  let rec loop off acc =
    if off < (length t)
    then loop (off + page_size) (Bigarray_compat.Array1.sub t off page_size :: acc)
    else acc in
  List.rev (loop 0 [])

let pages n =
  let rec inner acc n =
    if n > 0 then inner ((get 1)::acc) (n-1) else acc
  in inner [] n

let pages_order order = pages (1 lsl order)

let round_to_page_size n = ((n + page_size - 1) lsr 12) lsl 12

let to_cstruct t = Cstruct.of_bigarray t

exception Buffer_is_not_page_aligned
exception Buffer_not_multiple_of_page_size

let of_cstruct_exn x =
  let ba = Cstruct.to_bigarray x in
  if not(Cstruct.check_alignment x page_alignment) then
    raise Buffer_is_not_page_aligned;
  if Array1.dim ba land (page_size - 1) <> 0 then raise Buffer_not_multiple_of_page_size;
  ba

let to_string t =
  let result = Bytes.create (length t) in
  for i = 0 to length t - 1 do
    Bytes.set result i t.{i}
  done;
  Bytes.to_string result

let get_buf ?(n=1) () =
  to_cstruct (get n)

let blit src dest = Bigarray_compat.Array1.blit src dest

(* TODO: this is extremely inefficient.  Should use a ocp-endian
   blit rather than a byte-by-byte *)
let string_blit src srcoff dst dstoff len =
  for i = 0 to len - 1 do
    dst.{i+dstoff} <- src.[i+srcoff]
  done
