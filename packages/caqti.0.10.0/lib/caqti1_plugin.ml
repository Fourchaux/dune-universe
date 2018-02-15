(* Copyright (C) 2014--2017  Petter A. Urkedal <paurkedal@gmail.com>
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

exception Plugin_missing of string * string
exception Plugin_invalid of string * string

(* Because it lacks a cmxs? *)
module Really_link_CalendarLib = struct include CalendarLib end

let msg_invalid = "The plugin seemed to load, but did not register."
let ensure_plugin extract pkg =
  (match extract () with
   | Some x -> x
   | None ->
      (match !Caqti_connect.dynload_library pkg [@warning "-3"] with
       | Ok () ->
          (match extract () with
           | Some x -> x
           | None -> raise (Plugin_invalid (pkg, msg_invalid)))
       | Error msg -> raise (Plugin_missing (pkg, msg))))
