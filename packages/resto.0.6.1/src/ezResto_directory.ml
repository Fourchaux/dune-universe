(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(*  Copyright (C) 2016, OCamlPro.                                            *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Resto
open Lwt.Infix
open Resto_directory
module Directory = Resto_directory.Make (Resto_json.Encoding)
open Directory
module Answer = Answer

type step = Directory.step =
  | Static of string
  | Dynamic of Arg.descr
  | DynamicTail of Arg.descr

type conflict = Directory.conflict =
  | CService of meth
  | CDir
  | CBuilder
  | CTail
  | CTypes of Arg.descr * Arg.descr
  | CType of Arg.descr * string list

exception Conflict = Directory.Conflict

type directory = unit Directory.directory

let empty = empty

let prefix path dir = prefix path (map (fun _ -> Lwt.return_unit) dir)

let merge = merge

let register d s h = register d s h

let register0 d s h = register0 d s h

let register1 d s h = register1 d s h

let register2 d s h = register2 d s h

let register3 d s h = register3 d s h

let register4 d s h = register4 d s h

let register5 d s h = register5 d s h

let register_dynamic_directory ?descr dir path builder =
  register_dynamic_directory ?descr dir path (fun p ->
      builder p >>= fun dir -> Lwt.return (map (fun _ -> Lwt.return_unit) dir))

let register_dynamic_directory1 ?descr root s f =
  register_dynamic_directory ?descr root s Curry.(curry (S Z) f)

let register_dynamic_directory2 ?descr root s f =
  register_dynamic_directory ?descr root s Curry.(curry (S (S Z)) f)

let register_dynamic_directory3 ?descr root s f =
  register_dynamic_directory ?descr root s Curry.(curry (S (S (S Z))) f)

let register_describe_directory_service = register_describe_directory_service

type 'input input = 'input Service.input =
  | No_input : unit input
  | Input : 'input Json_encoding.encoding -> 'input input

type ('q, 'i, 'o, 'e) types = ('q, 'i, 'o, 'e) Directory.types = {
  query : 'q Resto.Query.t;
  input : 'i Service.input;
  output : 'o Json_encoding.encoding;
  error : 'e Json_encoding.encoding;
}

type registered_service = Directory.registered_service =
  | Service : {
      types : ('q, 'i, 'o, 'e) types;
      handler : 'q -> 'i -> ('o, 'e) Answer.t Lwt.t;
    }
      -> registered_service

type lookup_error = Directory.lookup_error

let lookup directory args query = Directory.lookup directory () args query

let allowed_methods dir path = Directory.allowed_methods dir () path

let transparent_lookup = Directory.transparent_lookup
