(* Copyright (c) 2013-2017 The Labrys developers. *)
(* See the LICENSE file at the top-level directory. *)

let unknown_loc =
  let pos = Location.{pos_lnum = -1; pos_cnum = -1} in
  Location.{loc_start = pos; loc_end = pos; filename = "unknown"}

let prelude options =
  Module.library_create options ["Prelude"]

let prelude_name = (unknown_loc, `UpperName ["Prelude"])
let t_unit_name = `UpperName ["Prelude"; "Unit"]

let unit options =
  Ident.Type.create ~loc:unknown_loc (prelude options) "Unit"
let int options =
  Ident.Type.create ~loc:unknown_loc (prelude options) "Int"
let float options =
  Ident.Type.create ~loc:unknown_loc (prelude options) "Float"
let char options =
  Ident.Type.create ~loc:unknown_loc (prelude options) "Char"
let string options =
  Ident.Type.create ~loc:unknown_loc (prelude options) "String"

let underscore_loc loc =
  Ident.Name.local_create ~loc "_"
let underscore_type_var_loc loc =
  Ident.Type.local_create ~loc "_"
let underscore_instance_loc loc =
  Ident.Instance.local_create ~loc "_"
let underscore =
  underscore_loc unknown_loc

let exn options = Ident.Type.create ~loc:unknown_loc (prelude options) "Exn"
let io options = Ident.Type.create ~loc:unknown_loc (prelude options) "IO"

let main ~current_module =
  Ident.Name.create ~loc:unknown_loc current_module "main"

let imports ~current_module options imports =
  let no_prelude = options#no_prelude in
  if no_prelude || Module.equal current_module (prelude options) then
    imports
  else
    ParseTree.Library prelude_name :: imports

let interface ~current_module options mimports tree =
  let no_prelude = options#no_prelude in
  let mimports = imports ~current_module options mimports in
  if no_prelude || Module.equal current_module (prelude options) then
    (mimports, tree)
  else
    (mimports, ParseTree.IOpen (ParseTree.Library prelude_name) :: tree)

let tree ~current_module options mimports tree =
  let no_prelude = options#no_prelude in
  let mimports = imports ~current_module options mimports in
  if no_prelude || Module.equal current_module (prelude options) then
    (mimports, tree)
  else
    (mimports, ParseTree.Open (ParseTree.Library prelude_name) :: tree)
