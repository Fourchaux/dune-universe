(*
 *  This file is part of the gym-http-api OCaml binding project.
 *
 * Copyright 2016-2017 IBM Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)

(** JSON type definition. *)

type safe = Yojson.Safe.json

type basic = Yojson.Basic.json

type json = basic

(** {6 Serialization/deserialization functions for atdgen} *)

type lexer_state = Yojson.Basic.lexer_state
type bi_outbuf_t = Bi_outbuf.t

val write_json : bi_outbuf_t -> json -> unit

val read_json : lexer_state -> Lexing.lexbuf -> json

val to_string : json -> string
