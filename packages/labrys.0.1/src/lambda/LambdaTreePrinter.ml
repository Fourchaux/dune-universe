(* Copyright (c) 2013-2017 The Labrys developers. *)
(* See the LICENSE file at the top-level directory. *)

open Utils.PPrint
open LambdaTree

let dump_name name = str (LIdent.to_string name)

let dump_constr_rep = function
  | Index idx -> OCaml.int idx
  | Exn name -> dump_name name

let dump_constr_rep_opt = function
  | None -> []
  | Some constr -> [dump_constr_rep constr]

let rec dump_tree = function
  | Switch (cases, def) ->
      str "Switch" ^^^ parens (dump_switch cases ^^ comma ^^^ dump_tree def)
  | Swap (idx, t) ->
      str "Swap" ^^^ parens (OCaml.int idx ^^ comma ^^^ dump_tree t)
  | Alias (name, t) ->
      str "Alias" ^^^ parens (dump_name name ^^ comma ^^^ dump_tree t)
  | Jump branch ->
      str "Jump" ^^^ OCaml.int branch
and dump_switch cases =
  brackets (separate_map (semi ^^ space) dump_switch_case cases)
and dump_switch_case (constr, len, t) =
  parens (dump_constr_rep constr ^^ comma ^^^ OCaml.int len ^^ comma ^^^ dump_tree t)

let dump_list l =
  brackets (separate (comma ^^ space) l)

let dump_tag_ty = function
  | `Int () -> str "Int"
  | `Float () -> str "Float"
  | `Char () -> str "Char"
  | `String () -> str "String"
  | `Custom -> str "Custom"
  | `Void -> str "Void"

let dump_arg_ty (ty, name) =
  dump_name name ^^^ colon ^^^ dump_tag_ty ty

let dump_args_ty args =
  dump_list (List.map dump_arg_ty args)

let dump_foreign_ty args ret =
  dump_args_ty args ^^^ str "->" ^^^ dump_tag_ty ret

let rec dump_let (name, is_rec, t) =
  let r = if is_rec then space ^^ str "rec" else empty in
  str "let" ^^ r ^^^ dump_name name ^^^ equals ^//^ dump_t t

and dump_branch t =
  bar ^^^ dump_t t

and dump_t = function
  | Abs (name, t) ->
      parens (str "λ" ^^^ dump_name name ^^^ str "->" ^//^ dump_t t)
  | App (f, x) ->
      parens (dump_name f ^//^ dump_name x)
  | Val name ->
      dump_name name
  | Datatype (rep, args) ->
      dump_list (dump_constr_rep_opt rep @ List.map dump_name args)
  | CallForeign (name, ret, args) ->
      str "Call" ^^^ parens (str name ^^^ colon ^^^ dump_foreign_ty args ret)
  | PatternMatching (t, vars, branches, tree) ->
      str "match" ^^^ dump_name t ^^^ str "with" ^/^
      braces (separate_map space dump_name vars) ^^^ str "in" ^/^
      separate_map hardline dump_branch branches ^/^
      str "from" ^^^ dump_tree tree ^/^
      str "end"
  | Let (name, is_rec, x, xs) ->
      parens (group (dump_let (name, is_rec, x) ^/^ str "in") ^/^ dump_t xs)
  | Fail t ->
      parens (str "fail" ^^^ dump_name t)
  | Try (t, (name, t')) ->
      str "try" ^^^ dump_t t ^^^ str "with" ^/^
      dump_name name ^^^ str "->" ^//^
      dump_t t' ^/^
      str "end"
  | RecordGet (t, n) ->
      dump_name t ^^ dot ^^ OCaml.int n
  | Const (`Int n) ->
      OCaml.int n
  | Const (`Float n) ->
      OCaml.float n
  | Const (`Char c) ->
      squotes (str (Utils.string_of_uchar c))
  | Const (`String s) ->
      dquotes (str s)
  | Unreachable ->
      str "Unreachable"

let dump_linkage = function
  | Public -> str "public"
  | Private -> str "private"

let dump_top = function
  | Value (name, t, linkage) ->
      dump_linkage linkage ^^^ dump_let (name, false, t)
  | Exception name ->
      str "exception" ^^^ dump_name name

let dump l =
  separate_map (hardline ^^ hardline) dump_top l
