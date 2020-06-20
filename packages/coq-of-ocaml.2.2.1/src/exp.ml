(** An expression. *)
open Typedtree
open SmartPrint
open Monad.Notations

module Header = struct
  type t = {
    name : Name.t;
    typ_vars : Name.t list;
    args : (Name.t * Type.t) list;
    structs : string list;
    typ : Type.t option }

  let to_coq_structs (header : t) : SmartPrint.t =
    match header.structs with
    | [] -> empty
    | _ :: _ ->
      let structs = separate space (List.map (fun s -> !^ s) header.structs) in
      braces (nest (!^ "struct" ^^ structs))
end

module Definition = struct
  type 'a t = {
    is_rec : Recursivity.t;
    cases : (Header.t * 'a) list }
end

type match_existential_cast = {
  new_typ_vars : Name.t list;
  bound_vars : (Name.t * Type.t) list;
  return_typ : Type.t;
  use_axioms : bool;
  cast_result : bool }

(** The simplified OCaml AST we use. We do not use a mutualy recursive type to
    simplify the importation in Coq. *)
type t =
  | Constant of Constant.t
  | Variable of MixedPath.t * string list
  | Tuple of t list (** A tuple of expressions. *)
  | Constructor of PathName.t * string list * t list
    (** A constructor name, some implicits, and a list of arguments. *)
  | Apply of t * t list (** An application. *)
  | Function of Name.t * t (** An argument name and a body. *)
  | LetVar of string option * Name.t * Name.t list * t * t
    (** The let of a variable, with optionally a list of polymorphic variables.
        We optionally specify the symbol of the let operator as it may be
        non-standard for monadic binds. *)
  | LetFun of t option Definition.t * t
  | LetTyp of Name.t * Name.t list * Type.t * t
    (** The definition of a type. It is used to represent module values. *)
  | LetModuleUnpack of Name.t * PathName.t * t
    (** Open a first-class module. *)
  | Match of t * (Pattern.t * match_existential_cast option * t) list * bool
    (** Match an expression to a list of patterns. *)
  | Record of (PathName.t * t) list
    (** Construct a record giving an expression for each field. *)
  | Field of t * PathName.t (** Access to a field of a record. *)
  | IfThenElse of t * t * t (** The "else" part may be unit. *)
  | Module of int Tree.t * (PathName.t * int * t) list
    (** The value of a first-class module. *)
  | ModuleNested of (string option * PathName.t * t) list
    (** The value of a first-class module inside another module
        (no existentials). There may be error messages.
        TODO: see if still useful. *)
  | ModuleCast of int Tree.t * MixedPath.t
    (** The cast of a module to another module type with potentially more
        existentials. *)
  | ModulePack of t (** Pack a module. *)
  | Functor of Name.t * Type.t * t
    (** A functor. *)
  | TypeAnnotation of t * Type.t
    (** Annotate with a type. *)
  | Assert of Type.t * t (** The assert keyword. *)
  | Error of string (** An error message for unhandled expressions. *)
  | ErrorArray of t list (** An error produced by an array of elements. *)
  | ErrorTyp of Type.t (** An error composed of a type. *)
  | ErrorMessage of t * string
    (** An expression together with an error message. *)

(** Take a function expression and make explicit the list of arguments and
    the body. *)
let rec open_function (e : t) : Name.t list * t =
  match e with
  | Function (x, e) ->
    let (xs, e) = open_function e in
    (x :: xs, e)
  | _ -> ([], e)

let error_message (e : t) (category : Error.Category.t) (message : string) : t Monad.t =
  raise (ErrorMessage (e, message)) category message

let error_message_in_module
  (field : Name.t option)
  (e : t)
  (category : Error.Category.t)
  (message : string)
  : (string option * Name.t option * t) option Monad.t =
  raise (Some (Some message, field, e)) category message

module ModuleTypValues = struct
  type t =
    | Module of Name.t
    | ModuleFunctor of Name.t
    | Value of Name.t * int

  let get
    (typ_vars : Name.t Name.Map.t)
    (module_typ : Types.module_type)
    : t list Monad.t =
    get_env >>= fun env ->
    match Mtype.scrape env module_typ with
    | Mty_signature signature ->
      signature |> Monad.List.filter_map (fun item ->
        match item with
        | Types.Sig_value (ident, { val_type; _ }, _) ->
          let* ident = Name.of_ident true ident in
          Type.of_typ_expr true typ_vars val_type >>= fun (_, _, new_typ_vars) ->
          return (Some (Value (
            ident,
            Name.Set.cardinal new_typ_vars
          )))
        | Sig_module (ident, _, { Types.md_type = Mty_functor _; _ }, _, _) ->
          let* name = Name.of_ident false ident in
          return (Some (ModuleFunctor name))
        | Sig_module (ident, _, _, _, _) ->
          let* name = Name.of_ident false ident in
          return (Some (Module name))
        | _ -> return None
      )
    | _ -> return []
end

let rec any_patterns_with_ith_true (is_guarded : bool) (i : int) (n : int)
  : Pattern.t list =
  if n = 0 then
    []
  else
    let head =
      if i = 0 && is_guarded then
        Pattern.Constructor (PathName.true_value, [])
      else
        Pattern.Any in
    head :: any_patterns_with_ith_true is_guarded (i - 1) (n - 1)

(** Import an OCaml expression. *)
let rec of_expression (typ_vars : Name.t Name.Map.t) (e : expression)
  : t Monad.t =
  Attribute.of_attributes e.exp_attributes >>= fun attributes ->
  set_env e.exp_env (
  set_loc (Loc.of_location e.exp_loc) (
  match e.exp_desc with
  | Texp_ident (path, loc, _) ->
    let implicits = Attribute.get_implicits attributes in
    MixedPath.of_path true path (Some loc.txt) >>= fun x ->
    return (Variable (x, implicits))
  | Texp_constant constant ->
    Constant.of_constant constant >>= fun constant ->
    return (Constant constant)
  | Texp_let (is_rec, cases, e2) ->
    of_expression typ_vars e2 >>= fun e2 ->
    of_let typ_vars is_rec cases e2
  | Texp_function {
      cases = [{
        c_lhs = {pat_desc = Tpat_var (x, _); _};
        c_rhs = e;
        _
      }];
      _
    }
  | Texp_function {
      cases = [{
        c_lhs = { pat_desc = Tpat_alias ({ pat_desc = Tpat_any; _ }, x, _); _ };
        c_rhs = e;
        _
      }];
      _
    } ->
    let* x = Name.of_ident true x in
    of_expression typ_vars e >>= fun e ->
    return (Function (x, e))
  | Texp_function { cases; _ } ->
    let is_gadt_match =
      Attribute.has_match_gadt attributes ||
      Attribute.has_match_gadt_with_result attributes in
    let do_cast_results = Attribute.has_match_gadt_with_result attributes in
    let is_with_default_case = Attribute.has_match_with_default attributes in
    open_cases typ_vars cases is_gadt_match do_cast_results is_with_default_case >>= fun (x, e) ->
    return (Function (x, e))
  | Texp_apply (e_f, e_xs) ->
    of_expression typ_vars e_f >>= fun e_f ->
    (e_xs |> Monad.List.filter_map (fun (_, e_x) ->
      match e_x with
      | Some e_x ->
        of_expression typ_vars e_x >>= fun e_x ->
        return (Some e_x)
      | None -> return None
    )) >>= fun e_xs ->
    let normal_apply = Apply (e_f, e_xs) in
    begin match (e_f, e_xs) with
    | (
        Variable (MixedPath.PathName path_name, []),
        [e1; Function (x, e2)]
      ) ->
      let* configuration = get_configuration in
      let name = PathName.to_string path_name in
      begin match Configuration.is_monadic_operator configuration name with
      | None -> return normal_apply
      | Some let_symbol -> return (LetVar (Some let_symbol, x, [], e1, e2))
      end
    | _ -> return normal_apply
    end
  | Texp_match (e, cases, _) ->
    let is_gadt_match =
      Attribute.has_match_gadt attributes ||
      Attribute.has_match_gadt_with_result attributes in
    let do_cast_results = Attribute.has_match_gadt_with_result attributes in
    let is_with_default_case = Attribute.has_match_with_default attributes in
    of_expression typ_vars e >>= fun e ->
    of_match typ_vars e cases is_gadt_match do_cast_results is_with_default_case
  | Texp_tuple es ->
    Monad.List.map (of_expression typ_vars) es >>= fun es ->
    return (Tuple es)
  | Texp_construct (_, constructor_description, es) ->
    let implicits = Attribute.get_implicits attributes in
    begin match constructor_description.cstr_tag with
    | Cstr_extension _ ->
      raise
        (Variable (
          MixedPath.of_name (Name.of_string_raw "extensible_type_value"),
          []
        ))
        ExtensibleType
        (
          "Values of extensible types are ignored.\n\n" ^
          "They are sent to a unit type."
        )
    | _ ->
      PathName.of_constructor_description constructor_description >>= fun x ->
      (es |> Monad.List.map (of_expression typ_vars)) >>= fun es ->
      return (Constructor (x, implicits, es))
    end
  | Texp_variant (label, e) ->
    PathName.constructor_of_variant label >>= fun path_name ->
    let constructor =
      Variable (MixedPath.PathName path_name, []) in
    begin match e with
    | None -> return constructor
    | Some e ->
      of_expression typ_vars e >>= fun e ->
      return (Apply (constructor, [e]))
    end
  | Texp_record { fields; extended_expression; _ } ->
      Array.to_list fields |> Monad.List.filter_map (
        fun (label_description, definition) ->
          begin match definition with
          | Kept _ -> return None
          | Overridden (_, e) ->
            PathName.of_label_description label_description >>= fun x ->
            return (Some (x, e))
          end >>= fun x_e ->
          match x_e with
          | None -> return None
          | Some (x, e) ->
            of_expression typ_vars e >>= fun e ->
            return (Some (x, e))
      ) >>= fun fields ->
      begin match extended_expression with
      | None -> return (Record fields)
      | Some extended_expression ->
        of_expression typ_vars extended_expression >>= fun extended_e ->
        return (
          List.fold_left
            (fun extended_e (x, e) ->
              Apply (
                Variable (MixedPath.PathName (PathName.prefix_by_with x), []),
                [e; extended_e]
              )
            )
            extended_e
            fields
        )
    end
  | Texp_field (e, _, label_description) ->
    PathName.of_label_description label_description >>= fun x ->
    of_expression typ_vars e >>= fun e ->
    return (Field (e, x))
  | Texp_ifthenelse (e1, e2, e3) ->
    of_expression typ_vars e1 >>= fun e1 ->
    of_expression typ_vars e2 >>= fun e2 ->
    (match e3 with
    | None -> return (Tuple [])
    | Some e3 -> of_expression typ_vars e3) >>= fun e3 ->
    return (IfThenElse (e1, e2, e3))
  | Texp_sequence (e1, e2) ->
    of_expression typ_vars e2 >>= fun e2 ->
    set_loc (Loc.of_location e1.exp_loc) (
    error_message
      (ErrorMessage (e2, "instruction_sequence \";\""))
      SideEffect
      (
        "Sequences of instructions are ignored (operator \";\")\n\n" ^
        "Alternative: use a monad to sequence side-effects."
      )
    )
  | Texp_try (e, _) ->
    of_expression typ_vars e >>= fun e ->
    error_message
      (Apply (Error "try", [e]))
      SideEffect
      (
        "Try-with are not handled\n\n" ^
        "Alternative: use sum types (\"option\", \"result\", ...) to represent an error case."
      )
  | Texp_setfield (e_record, _, { lbl_name; _ }, e) ->
    of_expression typ_vars e_record >>= fun e_record ->
    of_expression typ_vars e >>= fun e ->
    error_message
      (Apply (
        Error "set_record_field",
        [e_record; Constant (Constant.String lbl_name); e]
      ))
      SideEffect
      "Set record field not handled."
  | Texp_array es ->
    Monad.List.map (of_expression typ_vars) es >>= fun es ->
    error_message (ErrorArray es) NotSupported "Arrays not handled."
  | Texp_while _ ->
    error_message (Error "while") SideEffect "While loops not handled."
  | Texp_for _ ->
    error_message (Error "for") SideEffect "For loops not handled."
  | Texp_send _ ->
    error_message
      (Error "send")
      NotSupported
      "Sending method message is not handled"
  | Texp_new _ ->
    error_message
      (Error "new")
      NotSupported
      "Creation of new objects is not handled"
  | Texp_instvar _ ->
    error_message
      (Error "instance_variable")
      NotSupported
      "Creating an instance variable is not handled"
  | Texp_setinstvar _ ->
    error_message
      (Error "set_instance_variable")
      SideEffect
      "Setting an instance variable is not handled"
  | Texp_override _ ->
    error_message (Error "override") NotSupported "Overriding is not handled"
  | Texp_letmodule (
      x,
      _,
      _,
      {
        mod_desc = Tmod_unpack (
          { exp_desc = Texp_ident (path, _, _); _ },
          _
        );
        _
      },
      e
    ) ->
    let* x = Name.of_ident true x in
    PathName.of_path_with_convert false path >>= fun path_name ->
    of_expression typ_vars e >>= fun e ->
    return (LetModuleUnpack (x, path_name, e))
  | Texp_letmodule (x, _, _, module_expr, e) ->
    let* x = Name.of_ident true x in
    push_env (of_module_expr typ_vars module_expr None >>= fun value ->
    set_env e.exp_env (
    push_env (of_expression typ_vars e >>= fun e ->
    return (LetVar (None, x, [], value, e)))))
  | Texp_letexception _ ->
    error_message
      (Error "let_exception")
      SideEffect
      "Let of exception is not handled"
  | Texp_assert e' ->
    Type.of_typ_expr false typ_vars e.exp_type >>= fun (typ, _, _) ->
    of_expression typ_vars e' >>= fun e' ->
    error_message
      (Assert (typ, e'))
      SideEffect
      "Assert instruction is not handled."
  | Texp_lazy e ->
    of_expression typ_vars e >>= fun e ->
    error_message
      (Apply (Error "lazy", [e]))
      SideEffect
      "Lazy expressions are not handled"
  | Texp_object _ ->
    error_message
      (Error "object")
      NotSupported
      "Creation of objects is not handled"
  | Texp_pack module_expr ->
    push_env (of_module_expr typ_vars module_expr None) >>= fun e ->
    return (ModulePack e)
  | Texp_letop _ ->
    error_message
      (Error "let_op")
      NotSupported
      "We do not support let operators"
  | Texp_unreachable ->
    error_message
      (Error "unreachable")
      NotSupported
      "Unreachable expressions are not supported"
  | Texp_extension_constructor _ ->
    error_message
      (Error "extension")
      NotSupported
      "Construction of extensions is not handled"
  | Texp_open (_, e) -> of_expression typ_vars e))

and of_match
  (typ_vars : Name.t Name.Map.t)
  (e : t)
  (cases : case list)
  (is_gadt_match : bool)
  (do_cast_results : bool)
  (is_with_default_case : bool)
  : t Monad.t =
  (cases |> Monad.List.filter_map (fun {c_lhs; c_guard; c_rhs} ->
    set_loc (Loc.of_location c_lhs.pat_loc) (
    let* bound_vars =
      Typedtree.pat_bound_idents c_lhs |> List.rev |> Monad.List.map
        (fun ident ->
          let { Types.val_type; _ } =
            Env.find_value (Path.Pident ident) c_rhs.exp_env in
          let* name = Name.of_ident true ident in
          return (name, val_type)
        ) in
    Type.existential_typs_of_typs (List.map snd bound_vars) >>= fun existentials ->
    Monad.List.map
      (fun (name, typ) ->
        Type.of_typ_expr true typ_vars typ >>= fun (typ, _, _) ->
        return (name, typ)
      )
      bound_vars >>= fun bound_vars ->
    let free_vars = Type.local_typ_constructors_of_typs (List.map snd bound_vars) in
    let existentials = Name.Set.inter existentials free_vars in
    Type.of_typ_expr true typ_vars c_rhs.exp_type >>= fun (typ, _, _) ->
    let existential_cast =
      Some {
        new_typ_vars = Name.Set.elements existentials;
        bound_vars;
        return_typ = typ;
        use_axioms = is_gadt_match;
        cast_result = do_cast_results;
      } in
    begin match c_guard with
    | Some guard ->
      of_expression typ_vars guard >>= fun guard ->
      return (Some guard)
    | None -> return None
    end >>= fun guard ->
    Pattern.of_pattern c_lhs >>= fun pattern ->
    match c_rhs.exp_desc with
    | Texp_unreachable -> return None
    | _ ->
      of_expression typ_vars c_rhs >>= fun e ->
      return (
        Util.Option.map pattern (fun pattern ->
        (pattern, existential_cast, guard, e))
      )
    )
  )) >>= fun cases_with_guards ->
  let guards =
    cases_with_guards |> Util.List.filter_map (function
      | (p, _, Some guard, _) -> Some (p, guard)
      | _ -> None
    ) in
  let guard_checks =
    guards |> List.map (fun (p, guard) ->
      Match (
        e,
        [
          (p, None, guard);
          (
            Pattern.Any,
            None,
            Variable (MixedPath.PathName PathName.false_value, [])
          )
        ],
        false
      )
    ) in
  let e =
    match guards with
    | [] -> e
    | _ :: _ -> Tuple (e :: guard_checks) in
  let i = ref (-1) in
  let nb_guards = List.length guard_checks in
  let cases =
    cases_with_guards |> List.map (fun (p, existential_cast, guard, rhs) ->
      let is_guarded = match guard with Some _ -> true | None -> false in
      begin if is_guarded then
        i := !i + 1
      end;
      let p =
        if nb_guards = 0 then
          p
        else
          Pattern.Tuple (
            p :: any_patterns_with_ith_true is_guarded !i nb_guards
          ) in
      (p, existential_cast, rhs)
    ) in
  return (Match (e, cases, is_with_default_case))

(** Generate a variable and a "match" on this variable from a list of
    patterns. *)
and open_cases
  (typ_vars : Name.t Name.Map.t)
  (cases : case list)
  (is_gadt_match : bool)
  (do_cast_results : bool)
  (is_with_default_case : bool)
  : (Name.t * t) Monad.t =
  let name = Name.FunctionParameter in
  let e = Variable (MixedPath.of_name name, []) in
  let* e =
    of_match
      typ_vars e cases is_gadt_match do_cast_results is_with_default_case in
  return (name, e)

and import_let_fun
  (typ_vars : Name.t Name.Map.t)
  (at_top_level : bool)
  (is_rec : Asttypes.rec_flag)
  (cases : value_binding list)
  : t option Definition.t Monad.t =
  let is_rec = Recursivity.of_rec_flag is_rec in
  (cases |> Monad.List.filter_map (fun { vb_pat = p; vb_expr; vb_attributes; _ } ->
    Attribute.of_attributes vb_attributes >>= fun attributes ->
    let is_axiom = Attribute.has_axiom attributes in
    let struct_attributes = Attribute.get_structs attributes in
    set_env vb_expr.exp_env (
    set_loc (Loc.of_location p.pat_loc) (
    Pattern.of_pattern p >>= fun p ->
    (match p with
    | Some Pattern.Any -> return None
    | Some (Pattern.Variable x) -> return (Some x)
    | _ ->
      raise None Unexpected "A variable name instead of a pattern was expected."
    ) >>= fun x ->
    Type.of_typ_expr true typ_vars vb_expr.exp_type >>= fun (e_typ, typ_vars, new_typ_vars) ->
    match x with
    | None -> return None
    | Some x ->
      of_expression typ_vars vb_expr >>= fun e ->
      let (args_names, e_body) = open_function e in
      let (args_typs, e_body_typ) = Type.open_type e_typ (List.length args_names) in
      get_configuration >>= fun configuration ->
      let structs =
        match struct_attributes with
        | [] ->
          if Configuration.is_without_guard_checking configuration then
            match (Recursivity.to_bool is_rec, args_names) with
            | (true, x :: _) -> [Name.to_string x]
            | _ -> []
          else
            []
        | _ :: _ -> struct_attributes in
      let header = {
        Header.name = x;
        typ_vars = Name.Set.elements new_typ_vars;
        args = List.combine args_names args_typs;
        structs;
        typ = Some e_body_typ
      } in
      let e_body = if is_axiom then None else Some e_body in
      return (Some (header, e_body))
    )
  ))) >>= fun cases ->
  let result = { Definition.is_rec = is_rec; cases } in
  match (at_top_level, result) with
  | (false, { is_rec = Recursivity.New true; cases = _ :: _ :: _ }) ->
    raise
      result
      NotSupported
      "Mutually recursive definition are only handled at top-level"
  | _ -> return result

and of_let
  (typ_vars : Name.t Name.Map.t)
  (is_rec : Asttypes.rec_flag)
  (cases : Typedtree.value_binding list)
  (e2 : t)
  : t Monad.t =
  match cases with
  | [{
      vb_pat = {
        pat_desc =
          Tpat_construct (
            _,
            { cstr_res = { desc = Tconstr (path, _, _); _ }; _ },
            _
          );
        _
      };
      _
     }] when PathName.is_unit path ->
     raise
      (ErrorMessage (e2, "top_level_evaluation"))
      SideEffect
      "Top-level evaluations are ignored"
  | _ ->
    begin match cases with
    | [{ vb_expr = { exp_desc; exp_type; _ }; _ }] when
      begin match exp_desc with
      | Texp_function _ -> false
      | _ -> true
      end ->
      Type.of_typ_expr true typ_vars exp_type >>= fun (_, _, new_typ_vars) ->
      return (Name.Set.cardinal new_typ_vars <> 0)
    | _ -> return true
    end >>= fun is_function ->
    begin match cases with
    | [{ vb_pat = p; vb_expr = e1; _ }] when not is_function ->
      Pattern.of_pattern p >>= fun p ->
      of_expression typ_vars e1 >>= fun e1 ->
      begin match p with
      | Some (Pattern.Variable x) -> return (LetVar (None, x, [], e1, e2))
      | Some p -> return (Match (e1, [p, None, e2], false))
      | None -> return (Match (e1, [], false))
      end
    | _ ->
      import_let_fun typ_vars false is_rec cases >>= fun def ->
      return (LetFun (def, e2))
    end

and of_module_expr
  (typ_vars : Name.t Name.Map.t)
  (module_expr : Typedtree.module_expr)
  (module_type : Types.module_type option)
  : t Monad.t =
  let { mod_desc; mod_env; mod_loc; mod_type = local_module_type; _ } = module_expr in
  set_env mod_env (
  set_loc (Loc.of_location mod_loc) (
  match mod_desc with
  | Tmod_ident (path, loc) ->
    MixedPath.of_path false path (Some loc.txt) >>= fun mixed_path ->
    let default_result = return (Variable (mixed_path, [])) in
    IsFirstClassModule.is_module_typ_first_class local_module_type >>= fun is_first_class ->
    let local_module_type_path =
      match is_first_class with
      | Found local_module_type_path -> Some local_module_type_path
      | Not_found _ -> None in
    begin match module_type with
    | None -> default_result
    | Some module_type ->
      IsFirstClassModule.is_module_typ_first_class
        module_type >>= fun is_first_class ->
      begin match is_first_class with
      | Found module_type_path ->
        ModuleTypParams.get_module_typ_typ_params_arity module_type
          >>= fun module_typ_params_arity ->
        let* are_module_paths_similar =
          match local_module_type_path with
          | None -> return false
          | Some local_module_type_path ->
            let* comparison =
              PathName.compare_paths local_module_type_path module_type_path in
              return (comparison = 0) in
        if are_module_paths_similar then
          return (
            ModuleCast (
              module_typ_params_arity,
              mixed_path
            )
          )
        else
          ModuleTypValues.get typ_vars module_type >>= fun values ->
          begin
            values |> Monad.List.map (function
              | ModuleTypValues.Value (value, nb_free_vars) ->
                PathName.of_path_and_name_with_convert module_type_path value
                  >>= fun field_name ->
                begin match local_module_type_path with
                | Some local_module_type_path ->
                  PathName.of_path_with_convert false path >>= fun base ->
                  PathName.of_path_and_name_with_convert
                    local_module_type_path
                    value >>= fun field ->
                  return (MixedPath.Access ( base, [field], false))
                | None ->
                  PathName.of_path_and_name_with_convert path value
                    >>= fun path_name ->
                  return (MixedPath.PathName path_name)
                end >>= fun mixed_path ->
                return (
                  field_name,
                  nb_free_vars,
                  Variable (mixed_path, [])
                )
              | Module modul ->
                PathName.of_path_and_name_with_convert module_type_path modul
                  >>= fun field_name ->
                return (
                  field_name,
                  0,
                  Variable (
                    MixedPath.Access (PathName.of_name [] modul, [], false),
                    []
                  )
                )
              | ModuleFunctor functo ->
                PathName.of_path_and_name_with_convert module_type_path functo
                  >>= fun field_name ->
                return (
                  field_name,
                  0,
                  Variable (
                    MixedPath.PathName (PathName.of_name [] functo),
                    []
                  )
                )
            )
          end >>= fun fields ->
          return (Module (module_typ_params_arity, fields))
      | Not_found _ -> default_result
      end
    end
  | Tmod_structure structure ->
    let module_type =
      match module_type with
      | Some module_type -> module_type
      | None -> local_module_type in
    IsFirstClassModule.is_module_typ_first_class
      module_type >>= fun is_first_class ->
    begin match is_first_class with
    | IsFirstClassModule.Found signature_path ->
      of_structure
        typ_vars
        signature_path
        module_type
        structure.str_items
        structure.str_final_env
    | IsFirstClassModule.Not_found reason ->
      error_message
        (Error "first_class_module_value_of_unknown_signature")
        Module
        (
          "The signature name of this module could not be found\n\n" ^
          reason
        )
    end
  | Tmod_functor (ident, _, module_type_arg, e) ->
    begin match module_type_arg with
    | None ->
      error_message
        (Error "functor_without_argument_annotation")
        NotSupported
        "Expected an annotation to get the module type of the parameter of this functor"
    | Some module_type_arg ->
      let* x = Name.of_ident false ident in
      ModuleTyp.of_ocaml module_type_arg >>= fun module_type_arg ->
      of_module_expr typ_vars e None >>= fun e ->
      return (Functor (x, ModuleTyp.to_typ module_type_arg, e))
    end
  | Tmod_apply (e1, e2, _) ->
    let expected_module_typ_for_e2 =
      match e1.mod_type with
      | Mty_functor (_, module_typ_arg, _) -> module_typ_arg
      | _ -> None in
    let module_typ_for_application =
      match e1.mod_type with
      | Mty_functor (_, _, module_typ_result) -> Some module_typ_result
      | _ -> None in
    of_module_expr typ_vars e1 None >>= fun e1 ->
    of_module_expr typ_vars e2 expected_module_typ_for_e2 >>= fun e2 ->
    let application = Apply (e1, [e2]) in
    begin match (module_type, module_typ_for_application) with
    | (None, _) | (_, None) -> return application
    | (Some module_type, Some module_typ_for_application) ->
      ModuleTypParams.get_module_typ_typ_params_arity module_type
        >>= fun module_typ_params_arity ->
      ModuleTypParams.get_module_typ_typ_params_arity module_typ_for_application
        >>= fun module_typ_params_arity_for_application ->
      if module_typ_params_arity = module_typ_params_arity_for_application then
        return application
      else
        let functor_result_name = Name.of_string_raw "functor_result" in
        return (
          LetVar (
            None,
            functor_result_name,
            [],
            application,
            ModuleCast (
              module_typ_params_arity,
              MixedPath.Access (
                { path = []; base = functor_result_name },
                [],
                false
              )
            )
          )
        )
    end
  | Tmod_constraint (module_expr, mod_type, annotation, _) ->
    let module_type =
      match module_type with
      | Some _ -> module_type
      | None -> Some mod_type in
    of_module_expr typ_vars module_expr module_type >>= fun e ->
    begin match annotation with
    | Tmodtype_implicit -> return e
    | Tmodtype_explicit module_type ->
      ModuleTyp.of_ocaml module_type >>= fun module_type ->
      return (TypeAnnotation (e, ModuleTyp.to_typ module_type))
    end
  | Tmod_unpack (e, _) ->
    of_expression typ_vars e >>= fun e ->
    raise
      e
      Module
      (
        "We do not support unpacking of first-class module outside of " ^
        "expressions.\n\n" ^
        "This is to prevent universe inconsistencies in Coq. A module can " ^
        "become first-class but not the other way around."
      )
  ))

and of_structure
  (typ_vars : Name.t Name.Map.t)
  (signature_path : Path.t)
  (module_type : Types.module_type)
  (items : Typedtree.structure_item list)
  (final_env : Env.t)
  : t Monad.t =
  match items with
  | [] ->
    set_env final_env (
    ModuleTypParams.get_module_typ_typ_params_arity module_type >>=
      fun module_typ_params_arity ->
    ModuleTypValues.get typ_vars module_type >>= fun values ->
    begin
      values |> Monad.List.map (function
        | ModuleTypValues.Value (value, nb_free_vars) ->
          PathName.of_path_and_name_with_convert signature_path value
            >>= fun field_name ->
          return (
            field_name,
            nb_free_vars,
            Variable (MixedPath.of_name value, [])
          )
        | Module modul ->
          PathName.of_path_and_name_with_convert signature_path modul
            >>= fun field_name ->
          return (
            field_name,
            0,
            Variable (
              MixedPath.Access (PathName.of_name [] modul, [], false),
              []
            )
          )
        | ModuleFunctor functo ->
          PathName.of_path_and_name_with_convert signature_path functo
            >>= fun field_name ->
          return (
            field_name,
            0,
            Variable (
              MixedPath.PathName (PathName.of_name [] functo),
              []
            )
          )
      )
    end >>= fun fields ->
    return (Module (module_typ_params_arity, fields)))
  | item :: items ->
      set_env item.str_env (
      set_loc (Loc.of_location item.str_loc) (
      of_structure
        typ_vars signature_path module_type items final_env >>= fun e_next ->
      match item.str_desc with
      | Tstr_eval _ ->
        raise
          (ErrorMessage (e_next, "top_level_evaluation"))
          SideEffect
          "Top-level evaluations are ignored"
      | Tstr_value (rec_flag, cases) ->
        push_env (of_let typ_vars rec_flag cases e_next)
      | Tstr_primitive _ ->
        raise
          (ErrorMessage (e_next, "primitive"))
          NotSupported
          "Primitive not handled"
      | Tstr_type (_, typs) ->
        begin match typs with
        | [typ] ->
          begin match typ with
          | {
              typ_id;
              typ_type = {
                type_kind = Type_abstract;
                type_manifest = Some typ;
                type_params;
                _
              };
              _
            } ->
            let* name = Name.of_ident false typ_id in
            (type_params |> Monad.List.map Type.of_type_expr_variable) >>= fun typ_args ->
            Type.of_type_expr_without_free_vars typ >>= fun typ ->
            return (LetTyp (name, typ_args, typ, e_next))
          | _ ->
            raise
              (ErrorMessage (e_next, "typ_definition"))
              NotSupported
              "Only type synonyms are handled here"
          end
        | _ ->
          raise
            (ErrorMessage (e_next, "mutual_typ_definition"))
            NotSupported
            "Mutually recursive type definition not handled here"
        end
      | Tstr_typext _ ->
        raise
          (ErrorMessage (e_next, "type_extension"))
          ExtensibleType
          "We do not handle extensible types"
      | Tstr_exception _ ->
        raise
          (ErrorMessage (e_next, "exception"))
          SideEffect
          "Exception not handled"
      | Tstr_module { mb_id; mb_expr; _ } ->
        let* name = Name.of_ident false mb_id in
        of_module_expr
          typ_vars mb_expr (Some mb_expr.mod_type) >>= fun value ->
        return (LetVar (None, name, [], value, e_next))
      | Tstr_recmodule _ ->
        raise
          (ErrorMessage (e_next, "recursive_module"))
          NotSupported
          "Recursive modules not handled"
      | Tstr_modtype _ ->
        raise
          (ErrorMessage (e_next, "module_type"))
          NotSupported
          "Module type not handled in module with a named signature"
      | Tstr_open _ ->
        raise
          (ErrorMessage (e_next, "open"))
          NotSupported
          "Open not handled in module with a named signature"
      | Tstr_class _ ->
        raise
          (ErrorMessage (e_next, "class"))
          NotSupported
          "Class not handled"
      | Tstr_class_type _ ->
        raise
          (ErrorMessage (e_next, "class_type"))
          NotSupported
          "Class type not handled"
      | Tstr_include { incl_mod; incl_type; _ } ->
        begin match incl_mod.mod_desc with
        | Tmod_ident (path, _)
        | Tmod_constraint ({ mod_desc = Tmod_ident (path, _); _ }, _, _, _) ->
          let incl_module_type = Types.Mty_signature incl_type in
          IsFirstClassModule.is_module_typ_first_class
            incl_module_type >>= fun is_first_class ->
          begin match is_first_class with
          | Found incl_signature_path ->
            PathName.of_path_with_convert false path >>= fun path_name ->
            of_include typ_vars path_name incl_signature_path incl_type e_next
          | Not_found reason ->
            raise
              (ErrorMessage (e_next, "include_without_named_signature"))
              NotSupported
              (
                "We did not find a signature name for the include of this module\n\n" ^
                reason
              )
          end
        | _ ->
          raise
            (ErrorMessage (e_next, "unhandled_include"))
            NotSupported
            (
              "The include of this kind of module is not supported.\n\n" ^
              "Try to name this module and then include this name."
            )
        end
      | Tstr_attribute _ -> return e_next))

and of_include
  (typ_vars : Name.t Name.Map.t)
  (module_path_name : PathName.t)
  (signature_path : Path.t)
  (signature : Types.signature)
  (e_next : t)
  : t Monad.t =
  match signature with
  | [] -> return e_next
  | signature_item :: signature ->
    of_include typ_vars module_path_name signature_path signature e_next >>= fun e_next ->
    begin match signature_item with
    | Sig_value (ident, _, _) | Sig_type (ident, _, _, _) ->
      let is_value =
        match signature_item with Sig_value _ -> true | _ -> false in
      begin match signature_item with
      | Sig_value (_, { Types.val_type; _ }, _) ->
        Type.of_typ_expr true typ_vars val_type >>= fun (_, _, new_typ_vars) ->
        return (Name.Set.elements new_typ_vars)
      | _ -> return []
      end >>= fun typ_vars ->
      let* name = Name.of_ident is_value ident in
      PathName.of_path_and_name_with_convert signature_path name
        >>= fun signature_path_name ->
      return (
        LetVar (
          None,
          name,
          typ_vars,
          Variable (
            MixedPath.Access (module_path_name, [signature_path_name], false),
            []
          ),
          e_next
        )
      )
    | Sig_typext _ | Sig_module _ | Sig_modtype _ | Sig_class _
      | Sig_class_type _ -> return e_next
    end

let rec flatten_list (e : t) : t list option =
  match e with
  | Constructor (x, _, es) ->
    begin match (x, es) with
    | ({ PathName.path = []; base = Name.Make "[]" }, []) -> Some []
    | ({ PathName.path = []; base = Name.Make "cons" }, [e; es]) ->
      begin match flatten_list es with
      | Some es -> Some (e :: es)
      | None -> None
      end
    | _ -> None
    end
  | _ -> None

let to_coq_let_symbol (let_symbol : string option) : SmartPrint.t =
  match let_symbol with
  | None -> !^ "let"
  | Some let_symbol -> !^ let_symbol

(** Pretty-print an expression to Coq (inside parenthesis if the [paren] flag is
    set). *)
let rec to_coq (paren : bool) (e : t) : SmartPrint.t =
  match e with
  | Constant c -> Constant.to_coq c
  | Variable (x, implicits) ->
    let x = MixedPath.to_coq x in
    begin match implicits with
    | [] -> x
    | _ :: _ ->
      parens (separate space (
        x :: List.map (fun implicit -> !^ implicit) implicits)
      )
    end
  | Tuple es ->
    if es = [] then
      !^ "tt"
    else
      parens @@ nest @@ separate (!^ "," ^^ space) (List.map (to_coq true) es)
  | Constructor (x, implicits, es) ->
    let implicits = List.map (fun implicit -> !^ implicit) implicits in
    begin match flatten_list e with
    | Some [] ->
      let nil = !^ "nil" in
      begin match implicits with
      | [] -> nil
      | _ :: _ -> parens (separate space (nil :: implicits))
      end
    | Some es -> OCaml.list (to_coq false) es
    | None ->
      let arguments = implicits @ List.map (to_coq true) es in
      begin match arguments with
      | [] -> PathName.to_coq x
      | _ :: _ ->
        Pp.parens paren @@ nest @@
          separate space (PathName.to_coq x :: arguments)
      end
    end
  | Apply (e_f, e_xs) ->
    begin match (e_f, e_xs) with
    | (
        Variable (
          MixedPath.PathName {
            PathName.path = [Name.Make "Stdlib"];
            base = Name.Make "op_atat"
          },
          []
        ),
        [f; x]
      ) ->
      to_coq paren (Apply (f, [x]))
    | (
        Variable (
          MixedPath.PathName {
            PathName.path = [Name.Make "Stdlib"];
            base = Name.Make "op_pipegt"
          },
          []
        ),
        [x; f]
      ) ->
      to_coq paren (Apply (f, [x]))
    | _ ->
      Pp.parens paren @@ nest @@ (separate space (List.map (to_coq true) (e_f :: e_xs)))
    end
  | Function (x, e) ->
    Pp.parens paren @@ nest (!^ "fun" ^^ Name.to_coq x ^^ !^ "=>" ^^ to_coq false e)
  | LetVar (let_symbol, x, typ_params, e1, e2) ->
    let get_default () =
      Pp.parens paren @@ nest (
        to_coq_let_symbol let_symbol ^^ Name.to_coq x ^^
        begin match typ_params with
        | [] -> empty
        | _ :: _ ->
          braces (nest (
            separate space (typ_params |> List.map Name.to_coq) ^^
            !^ ":" ^^ !^ "Set"
          ))
        end ^^
        !^ ":=" ^^ to_coq false e1 ^^ !^ "in" ^^ newline ^^ to_coq false e2
      ) in
    begin match (let_symbol, x, e1, e2) with
    | (
        None,
        _,
        Variable (PathName { path = []; base }, []),
        _
     ) when Name.equal base x ->
      to_coq paren e2
    | (
        _,
        Name.FunctionParameter,
        _,
        Match (
          Variable (
            MixedPath.PathName {
              PathName.path = [];
              base = Name.FunctionParameter
            },
            []
          ),
          cases,
          is_with_default_case
        )
      ) ->
      let single_let =
        to_coq_try_single_let_pattern
          paren let_symbol
          e1 cases is_with_default_case in
      begin match single_let with
      | Some single_let -> single_let
      | None -> get_default ()
      end
    | _ -> get_default ()
    end
  | LetFun (def, e) ->
    (* There should be only on case for recursive definitionss. *)
    Pp.parens paren @@ nest (separate newline
      (def.Definition.cases |> List.mapi (fun index (header, e) ->
        let first_case = index = 0 in
        (if first_case then (
          !^ "let" ^^
          (if Recursivity.to_bool def.Definition.is_rec then !^ "fix" else empty)
        ) else
          !^ "with") ^^
        Name.to_coq header.Header.name ^^
        (if header.Header.typ_vars = []
        then empty
        else braces @@ group (
          separate space (List.map Name.to_coq header.Header.typ_vars) ^^
          !^ ":" ^^ Pp.set)) ^^
        group (separate space (header.Header.args |> List.map (fun (x, x_typ) ->
          parens (nest (
            Name.to_coq x ^^ !^ ":" ^^ Type.to_coq None None x_typ
          )))
        )) ^^
        Header.to_coq_structs header ^^
        (match header.Header.typ with
        | None -> empty
        | Some typ -> !^ ": " ^-^ Type.to_coq None None typ) ^-^
        !^ " :=" ^^ newline ^^
        indent (
          match e with
          | None -> !^ "axiom"
          | Some e -> to_coq false e
        )
      )) ^^ !^ "in" ^^ newline ^^ to_coq false e)
  | LetTyp (x, typ_args, typ, e) ->
    Pp.parens paren @@ nest (
      !^ "let" ^^ Name.to_coq x ^^
      begin match typ_args with
      | [] -> empty
      | _ -> parens (separate space (List.map Name.to_coq typ_args) ^^ !^ ":" ^^ Pp.set)
      end ^^ !^ ":" ^^ Pp.set ^^ !^ ":=" ^^
      Type.to_coq None None typ ^^ !^ "in" ^^
      newline ^^ to_coq false e
    )
  | LetModuleUnpack (x, path_name, e2) ->
    Pp.parens paren @@ nest (
      !^ "let" ^^
      !^ "'existS" ^^ !^ "_" ^^ !^ "_" ^^ Name.to_coq x ^^ !^ ":=" ^^
      PathName.to_coq path_name ^^ !^ "in" ^^ newline ^^
      to_coq false e2
    )
  | Match (e, cases, is_with_default_case) ->
    let single_let =
      to_coq_try_single_let_pattern
        paren None
        e cases is_with_default_case in
    begin match single_let with
    | Some single_let -> single_let
    | None ->
      let has_existential_cases =
        cases |> List.exists (function
          | (_, Some { new_typ_vars = _ :: _; _ }, _)
          | (_, Some { use_axioms = true; _ }, _) ->
            true
          | _ -> false
        ) in
      let is_large_match = has_existential_cases && List.length cases >= 5 in
      let separator =
        if is_large_match then
          newline
        else
          space in
      nest (
        !^ "match" ^^ to_coq false e ^^ !^ "with" ^^ newline ^^
        separate separator (cases |> List.map (fun (p, existential_cast, e) ->
          nest (
            !^ "|" ^^ Pattern.to_coq false p ^^ !^ "=>" ^^
            to_coq_cast_existentials existential_cast e ^^ newline
          )
        )) ^^
        (if is_with_default_case then
          !^ "|" ^^ !^ "_" ^^ !^ "=>" ^^ !^ "unreachable_gadt_branch" ^^ newline
        else
          empty
        ) ^^
        !^ "end"
      )
    end
  | Record fields ->
    nest (
      !^ "{|" ^^ separate (!^ ";" ^^ space) (fields |> List.map (fun (x, e) ->
        nest (PathName.to_coq x ^-^ !^ " :=" ^^ to_coq false e)
      )) ^^ !^ "|}"
    )
  | Field (e, x) -> to_coq true e ^-^ !^ ".(" ^-^ PathName.to_coq x ^-^ !^ ")"
  | IfThenElse (e1, e2, e3) ->
    Pp.parens paren @@ nest (
      !^ "if" ^^ to_coq false e1 ^^ !^ "then" ^^ newline ^^
      indent (to_coq false e2) ^^ newline ^^
      !^ "else" ^^ newline ^^
      indent (to_coq false e3))
  | Module (module_typ_params_arity, fields) ->
    to_coq_exist_t paren module_typ_params_arity (
      group (
        !^ "{|" ^^ newline ^^
        indent (separate (!^ ";" ^^ newline) (fields |> List.map (fun (x, nb_free_vars, e) ->
          nest (
            group (
              nest (
                PathName.to_coq x ^^
                begin match nb_free_vars with
                | 0 -> empty
                | _ -> braces (nest (separate space (Pp.to_coq_n_underscores nb_free_vars)))
                end
              ) ^^
              !^ ":="
            ) ^^
            to_coq false e)
          )
        )) ^^ newline ^^
        !^ "|}"
      )
    )
  | ModuleNested fields ->
    Pp.parens paren @@ nest (
      !^ "{|" ^^ newline ^^
      indent @@ separate (!^ ";" ^^ newline) (fields |> List.map (fun (error_message, x, e) ->
        (match error_message with
        | None -> empty
        | Some error_message -> Error.to_comment error_message ^^ newline) ^^
        nest (PathName.to_coq x ^-^ !^ " :=" ^^ to_coq false e)
      )) ^^ newline ^^
      !^ "|}"
    )
  | ModuleCast (module_typ_params_arity, module_path) ->
    to_coq_exist_t paren module_typ_params_arity (MixedPath.to_coq module_path)
  | ModulePack e -> parens @@ nest (!^ "pack" ^^ to_coq true e)
  | Functor (x, typ, e) ->
    Pp.parens paren @@ nest (
      !^ "fun" ^^
      parens (nest (Name.to_coq x ^^ !^ ":" ^^ Type.to_coq None None typ)) ^^
      !^ "=>" ^^ to_coq false e
    )
  | TypeAnnotation (e, typ) ->
    parens @@ nest (to_coq true e ^^ nest (!^ ":" ^^ Type.to_coq None None typ))
  | Assert (typ, e) ->
    Pp.parens paren @@ nest (
      !^ "assert" ^^ Type.to_coq None (Some Type.Context.Apply) typ ^^
      to_coq true e
    )
  | Error message -> !^ message
  | ErrorArray es -> OCaml.list (to_coq false) es
  | ErrorTyp typ -> Pp.parens paren @@ Type.to_coq None None typ
  | ErrorMessage (e, error_message) ->
    group (Error.to_comment error_message ^^ newline ^^ to_coq paren e)

and to_coq_try_single_let_pattern
  (paren : bool)
  (let_symbol : string option)
  (e : t)
  (cases : (Pattern.t * match_existential_cast option * t) list)
  (is_with_default_case : bool)
  : SmartPrint.t option =
  match (cases, is_with_default_case) with
  | ([(pattern, existential_cast, e2)], false)
    when not (Pattern.has_or_patterns pattern) ->
    Some (Pp.parens paren @@ nest (
      to_coq_let_symbol let_symbol ^^ !^ "'" ^-^
      Pattern.to_coq false pattern ^-^ !^ " :=" ^^
      to_coq false e ^^ !^ "in" ^^ newline ^^
      to_coq_cast_existentials existential_cast e2
    ))
  | _ -> None

and to_coq_cast_existentials
  (existential_cast : match_existential_cast option)
  (e : t)
  : SmartPrint.t =
  let e =
    match existential_cast with
    | Some { return_typ; cast_result = true; _ } ->
      group (
        nest (
          !^ "cast" ^^
          Type.to_coq None (Some Type.Context.Apply) return_typ
        ) ^^
        to_coq true e
      )
    | _ -> to_coq false e in
  match existential_cast with
  | None -> e
  | Some { new_typ_vars; bound_vars; use_axioms; _ } ->
    let variable_names =
      Pp.primitive_tuple (bound_vars |> List.map (fun (name, _) ->
        Name.to_coq name
      )) in
    let variable_typ paren =
      match bound_vars with
      | [(_, typ)] ->
        let context = if paren then Some (Type.Context.Apply) else None in
        Type.to_coq None context typ
      | _ ->
        Pp.primitive_tuple_type (bound_vars |> List.map (fun (_, typ) ->
          Type.to_coq None None typ
        )) in
    begin match (bound_vars, new_typ_vars) with
    | ([], _) -> e
    | (_, []) ->
      if use_axioms then
        let variable_names_pattern =
          match bound_vars with
          | [_] -> variable_names
          | _ -> !^ "'" ^-^ variable_names in
        nest (
          !^ "let" ^^ variable_names_pattern ^^ !^ ":=" ^^
          nest (!^ "cast" ^^ variable_typ true ^^ variable_names) ^^
          !^ "in" ^^ newline ^^
          e
        )
      else
        e
    | _ ->
      let existential_names =
        Pp.primitive_tuple (List.map Name.to_coq new_typ_vars) in
      let existential_names_pattern =
        Pp.primitive_tuple_pattern (List.map Name.to_coq new_typ_vars) in
      nest (
        !^ "let" ^^ !^ "'existT" ^^ !^ "_" ^^ existential_names ^^
        variable_names ^^ !^ ":=" ^^
        nest (
          let (operator, option) =
            if use_axioms then
              ("cast_exists", "Es")
            else
              ("existT", "A") in
          !^ operator ^^
          nest (parens (
            !^ option ^^ !^ ":=" ^^
            Pp.primitive_tuple_type (List.map (fun _ -> Pp.set) new_typ_vars)
          )) ^^
          parens (nest (
            !^ "fun" ^^ existential_names_pattern ^^ !^ "=>" ^^ variable_typ false
          )) ^^
          begin if use_axioms then
            empty
          else
            Pp.primitive_tuple_infer (List.length new_typ_vars)
          end ^^
          variable_names
        ) ^^ !^ "in" ^^ newline ^^
        e
      )
    end

and to_coq_exist_t
  (paren : bool)
  (module_typ_params_arity : int Tree.t)
  (e : SmartPrint.t)
  : SmartPrint.t =
  let arities = Tree.flatten module_typ_params_arity |> List.map snd in
  let nb_of_existential_variables = List.length arities in
  Pp.parens paren @@ nest (
    !^ "existT" ^^
    parens (nest (
      !^ "A :=" ^^
      Pp.primitive_tuple_type (List.map Pp.typ_arity arities)
    )) ^^
    begin match nb_of_existential_variables with
    | 0 -> !^ "(fun _ => _)"
    | _ -> !^ "_"
    end ^^
    Pp.primitive_tuple_infer nb_of_existential_variables ^^
    e
  )
