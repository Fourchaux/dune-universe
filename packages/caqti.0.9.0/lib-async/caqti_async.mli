(* Copyright (C) 2014--2018  Petter A. Urkedal <paurkedal@gmail.com>
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version, with the OCaml static compilation exception.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *)

(** Connector for Async. *)

open Async

include Caqti_connect_sig.S with type 'a future := 'a Deferred.t

(**/**)

module V2 : Caqti_connect_sig.S
  with type 'a future := 'a Deferred.t
   and module Pool = Pool
[@@deprecated "Now moved to the Caqti_async top level."]
