(* This file is part of the Catala compiler, a specification language for tax and social benefits
   computation rules. Copyright (C) 2020 Inria, contributor: Denis Merigoux
   <denis.merigoux@inria.fr>

   Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
   in compliance with the License. You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software distributed under the License
   is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
   or implied. See the License for the specific language governing permissions and limitations under
   the License. *)

(** Concise syntax with English abbreviated keywords. *)

val is_code : bool ref
(** Boolean reference, used by the lexer as the mutable state to distinguish whether it is lexing
    code or law. *)

val code_string_acc : string ref
(** Mutable string reference that accumulates the string representation of the body of code being
    lexed. This string representation is used in the literate programming backends to faithfully
    capture the spacing pattern of the original program *)

val update_acc : Sedlexing.lexbuf -> unit
(** Updates {!val:code_string_acc} with the current lexeme *)

val raise_lexer_error : Utils.Pos.t -> string -> 'a
(** Error-generating helper *)

val token_list_language_agnostic : (string * Parser.token) list
(** Associative list matching each punctuation string part of the Catala syntax with its {!module:
    Surface.Parser} token. Same for all the input languages (English, French, etc.) *)

val token_list : (string * Parser.token) list
(** Same as {!val: token_list_language_agnostic}, but with tokens whose string varies with the input
    language. *)

val lex_code : Sedlexing.lexbuf -> Parser.token
(** Main lexing function used in a code block *)

val lex_law : Sedlexing.lexbuf -> Parser.token
(** Main lexing function used outside code blocks *)

val lexer : Sedlexing.lexbuf -> Parser.token
(** Entry point of the lexer, distributes to {!val: lex_code} or {!val: lex_law} depending of {!val:
    is_code}. *)
