(*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
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

open Result

module Make(Ip:Mirage_protocols_lwt.IP) : sig

  type error = Mirage_protocols.Ip.error

  val pp_error: error Fmt.t

  type id

  val src_port_of_id : id -> int

  val dst_of_id : id -> (Ip.ipaddr * int)

  val wire : src:Ip.ipaddr -> src_port:int -> dst:Ip.ipaddr -> dst_port:int -> id

  val pp_id : Format.formatter -> id -> unit

  val xmit : ip:Ip.t -> id:id ->
    ?rst:bool -> ?syn:bool -> ?fin:bool -> ?psh:bool ->
    rx_ack:Sequence.t option -> seq:Sequence.t -> window:int ->
    options:Options.t list ->
    Cstruct.t -> (unit, error) result Lwt.t

end
