(*---------------------------------------------------------------------------
   Copyright (c) 2016 Anil Madhavapeddy. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   jekyll-format v0.3.0
  ---------------------------------------------------------------------------*)

open Astring
open Rresult
module JF = Jekyll_format

type t = {
  fname : string option;
  title : string;
  date : Ptime.t;
  slug : string;
  body : Jekyll_format.body;
  fields : Jekyll_format.fields;
}

let result_to_exn = function
  | Ok r -> r
  | Error (`Msg m) -> raise (JF.Parse_failure m)

let of_string ?fname post =
  let open R.Infix in
  JF.of_string post >>= fun jf ->
  let body = JF.body jf in
  let fields = JF.fields jf in
  JF.title ?fname fields >>= fun title ->
  JF.date ?fname fields >>= fun date ->
  JF.slug ?fname fields >>= fun slug ->
  Ok { fname; title; date; body; slug; fields }

let of_string_exn ?fname post = of_string ?fname post |> result_to_exn

let compare a b =
  match Ptime.compare a.date b.date with 0 -> compare a.title b.title | n -> n

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Anil Madhavapeddy

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
