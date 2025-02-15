[@@@warning "-26"]
open Core
open Generic_types

let split_last ls =
  let rec loop ls acc =
    match ls with
    | [] ->
      acc |> Option.map ~f:(fun (ls,it) -> List.rev ls, it)
    | h :: t ->
      let acc = match acc with
        | None -> Some ([], h)
        | Some (belast,last) ->
          Some (last :: belast, h) in
      loop t acc
  in
  loop ls None

type type_seq =
  | TyArrow                     (* T1 -> T2 *)
  | TyTuple                     (* T1 * ... * Tn *)
  | TyConstr                    (* tconst | T tconstr | (T1, ..., Tn) tconstr *)
  | TyObj                       (* < l1:T1; ...; ln:Tn > *)
  | TyClass                     (* #tconstr *)
  | TyAlias                     (* T as 'a *)
  | TyVariant                   (* [`A | `B] *)
  | TyPoly                      (* 'a. T *)
  | TyPackage                   (* (module S) *)
  | TyExtension                 (* [%id] *)
  | TyObjectField               (* inherit T1 | A : T1 -> T2 *)
  | TyPackageField               (* val S : T1 -> T2 *)
  | TyRowField               (* inherit T1 | A : T1 -> T2 *)
[@@deriving show]
type unwrapped_type =
  | ConstructorDefinition         (* _ A of b _ *)
  | LabelSpecification            (* _ x : t _ *)
  | TypeExtensionCase             (* t += _ | C of a _ *)
  | TypeExtension                 (* t += e *)
  | Apply                         (* _ f a b c _ *)
  | Array                         (* _ [x;y;z] _ *)
  | Assert                        (* _ assert E _ *)
  | AssignField                   (* x <- 2 *)
  | BindingOp                     (* _ (let+) _ *)
  | ClassArrow                    (* _ T -> CT _ *)
  | ClassConstraint               (* _ constraint T1 = T2 _  *)
  | ClassConstructor              (* _ c [ 'a, .... 'a] _ *)
  | ClassField                    (* _ [@@ A] _  *)
  | ClassInherit                  (* _ inherit CE _ *)
  | ClassInitializer              (* _ initializer E _ *)
  | ClassObject                   (* _ object ... end _ *)
  | ClassObjectType               (* _ object ... end _ *) (* only has types *)
  | ClassOpen                     (* _ let open E in CS _ *)
  | ClassSignature                (* _ object ... end  _  *)
  | ClassStructure                (* _ object ... end  _  *)
  | ClassTypeDefinition           (* _ class s = object ... end _  *)
  | ClassTypeDeclaration          (* _ class s = object ... end _  *) (* only has types*)
  | ClassDefinition               (* _ class s = object ... end _  *)
  | ClassTypeField                (* _ [@@ A ] _ *)
  | Coerce                        (* _ E1 : T1 :> T2 _ *)
  | Constraint                    (* _ E1 : T1 _ *)
  | Constructor                   (* C E *)
  | Eval                          (* module M = begin _ assert true _  end *)
  | Extension                     
  | For                           (* _ for E1 to E2 do E3 done _ *)
  | Function                      (* _ function A -> B | ... | X -> Z _ *)
  | GetField                      (* _ x.(y) _ *)
  | IfThenElse                    (* _ if E1 then E2 else E3 _ *)
  | LabelDeclaration
  | Lambda
  | Lazy
  | LetBinding                    (* _ let P1 = E1 in E2 _ *)
  | LetException
  | LetModuleBinding              (* _ M = X _ *)
  | LetModule                     (* _ let module M = x in E _*)
  | LetOp
  | Match                         (* _ match X with _ -> | ... | _ -> E3 _*)
  | MethodDeclaration             (* _ method x = E _ *)
  | MethodType                    (* _ method x : T _ *)
  | ModuleApply                   (* module X = _ X (Y) _ *)
  | ModuleBinding                 (* _ Name = ME _*)
  | ModuleConstraint              (* module X = _ X : Y _ *)
  | ModuleName                    (* module X = _ Example _*)
  | ModuleOpen                    (* _ open M _ *)
  | ModuleSubst                   (* _ module X := M _ *)
  | ModuleTypeOf                  (* _ module type of ME _ *)
  | ModuleTypeWithConstraint      (* MT with ... *)
  | ModuleFunctor                 (* _ functor (X: MT) -> ME _ *)
  | ModuleTypeFunctor             (* _ functor(X : MT1) -> MT2 _ *)
  | ModuleDeclaration             (* _ module M = MT _ *)
  | ModuleDefinition              (* _ module M = MEXPR _ *)
  | ModuleTypeDefinition          (* _ module type M = X _ *)
  | ModuleSignature               (* _ sig ... end _ *)
  | ModuleStructure               (* _ struct ... end _ *)
  | ModuleUnpack                  (* let module X = _ (val X) _ *)
  | New                           (* _ new M.c _ *)
  | LambdaType                    (* fun (type t) E*)
  | Override                      (* _ <E1, .. E2> _ *)
  | OverrideField                 (* _ X1=X2; ...; Xn = En > _ *)
  | PackModule                    (* _ (module ME) _*)
  | Poly                          (* fun x -> _ (e : t ) _*)
  | RecordField                   (* _  x=y _ *)
  | Record                        (* _ { x=y; ... ; } _ *)
  | Send                          (* _ E1 # m _ *)
  | Seq                           (* _ E1; E2; E3; _ *) (* Note: auto unwrapped into sequence*)
  | SetField                      (* _ x.(y) <- j _ *)
  | Try                           (* _ try X with _ -> | ... | _ -> E3 _ *)
  | Tuple                         (* _ (E1,...,EN) _ *)
  | TypeDefinition                (* _ type t1 = ... and ... and tn = ... *)
  | TypeDeclaration               (* _ type t1 = t2 _ *)
  | TypeConstraint                (* _ constraint t1 = t2 _ *)
  | ValueBinding                  (* _ let P1 = E1 _ *)
  | ExceptionDefinition           (* _ exception E _ *)
  | ValueDeclaration              (* _ val x : t _ *)
  | Variant                       (* _ `A _ *)
  | While                         (* _ while E1 do E2 done _ *)
  | WithConstraint                (* _ with type t1 = t2 _ *)
  | Pattern
  | Type of type_seq
[@@deriving show]

type t =
  | Signature_item of Parsetree.signature_item[@opaque]
  | Structure_item of Parsetree.structure_item[@opaque]
  | Value_binding of Parsetree.value_binding[@opaque]
  | Type_declaration of Parsetree.type_declaration[@opaque]
  | Attribute of Parsetree.attribute[@opaque]
  | CoreType of Parsetree.core_type[@opaque]
  | Pattern of Parsetree.pattern[@opaque]
  | Expression of Parsetree.expression[@opaque]
  | Text of Text_region.t
  | Wildcard of Text_region.t 
  | Sequence of ((Text_region.t * unwrapped_type) option * t list * t * t list)[@opaque]
  | EmptySequence of Text_region.t * unwrapped_type[@opaque]
  (* Note: Generally all "sequences" that were produced from normal
     OCaml code will not be empty - this additional variant is
     included specifically to handle strange asts produced by zipper
     based modifications *)


let rec to_string =
  let truncate ?(n = 15) items =
    let items = if String.length items > n then (String.slice items 0 n) ^ "..." else items in
    items
  in 
  function
  | Signature_item _si ->
    (Printf.sprintf "Signature_item")
  | Structure_item _si -> "Structure_item" (* " - {" ^ (Pprintast.string_of_structure [si]) ^ "}" *)
  | Value_binding _ -> "Value_binding"
  | Type_declaration _ -> "Type_declaration"
  | Wildcard _ -> "Wildcard"
  | Attribute  _ -> "Attribute of"
  | CoreType  _ -> "CoreType of"
  | Pattern  _ -> "Pattern of"
  | Text _ -> "Text"
  | Expression _ -> "Expression of"
  | Sequence  (bound, left, current, right) ->
    let bound = match bound with
      | None -> ""
      | Some (_,s) -> show_unwrapped_type s
    in
    let items = List.map ~f:to_string (left @ current :: right)
                |> String.concat ~sep:", " in
    let items = if String.length items > 20 then (String.slice items 0 20) ^ "..." else items in 
    "Sequence of " ^ bound ^ " (" ^ items ^  ")"
  | EmptySequence (_, ty) -> "EmptySequence of " ^ (show_unwrapped_type ty)


(** Huet's zipper for asts *)
type zipper =
  | Top
  | Node of {
      bounds: (Text_region.t * unwrapped_type) option;
      below: t list;
      parent: zipper;
      above: t list;
    }

type location =
  | MkLocation of t * zipper

let rec t_to_bounds = function
  | Text s -> s
  | Wildcard s -> s
  | Signature_item si ->
    let (iter,get) = Text_region.ast_bounds_iterator () in
    iter.signature_item iter si;
    get ()
  | Structure_item si ->
    let (iter,get) = Text_region.ast_bounds_iterator () in
    iter.structure_item iter si;
    get ()
  | CoreType ct ->
    let (iter,get) = Text_region.ast_bounds_iterator () in
    iter.typ iter ct;
    get ()
  | Attribute attr ->
    let (iter,get) = Text_region.ast_bounds_iterator () in
    iter.attribute iter attr;
    get ()
  | Type_declaration tdcl ->
    let (iter,get) = Text_region.ast_bounds_iterator () in
    iter.type_declaration iter tdcl;
    get ()
  | Value_binding vb ->
    let (iter,get) = Text_region.ast_bounds_iterator () in
    iter.value_binding iter vb;
    get ()
  | Pattern pat ->
    let (iter,get) = Text_region.ast_bounds_iterator () in
    iter.pat iter pat;
    get ()
  | Expression expr ->
    let (iter,get) = Text_region.ast_bounds_iterator () in
    iter.expr iter expr;
    get ()
  (* if its a sequence, take the union *)
  | Sequence (None, left,elem,right) ->
    List.map ~f:t_to_bounds (left @ right)
    |> List.fold ~f:(fun  a b  -> Text_region.union a b ) ~init:(t_to_bounds elem)
  | Sequence (Some region, left,elem,right) ->
    List.map ~f:t_to_bounds (left @ elem :: right)
    |> List.fold ~f:Text_region.union ~init:(fst region)
  | EmptySequence (b,_) -> b

let t_shift_by_offset ~diff t =
  let rec map t =
    let mapper = Text_region.ast_bounds_mapper ~diff in
    match t with
    | Signature_item si -> Signature_item (mapper.signature_item mapper si)
    | Structure_item si  -> Structure_item (mapper.structure_item mapper si)
    | Attribute si  -> Attribute (mapper.attribute mapper si)
    | CoreType si  -> CoreType (mapper.typ mapper si)
    | Value_binding vb -> Value_binding (mapper.value_binding mapper vb)
    | Type_declaration tdcl -> Type_declaration (mapper.type_declaration mapper tdcl)
    | Pattern pat -> Pattern (mapper.pat mapper pat)
    | Expression expr -> Expression (mapper.expr mapper expr)
    | Text s -> Text (Text_region.shift_region s diff)
    | Wildcard s -> Wildcard (Text_region.shift_region s diff)
    | Sequence (bounds, left,elem,right) ->
      let left = List.map ~f:map left in
      let right = List.map ~f:map right in
      let elem = map elem in
      let bounds = match bounds with
        | None -> None
        | Some (region,ty) ->
          let region = Text_region.shift_region region diff in
          Some (region,ty)
      in
      Sequence (bounds, left, elem, right)
    | EmptySequence (region,ty)  ->
      let region = Text_region.shift_region region diff in
      EmptySequence (region,ty) in
  map t

let t_list_to_bounds ls =
  match ls with
  | h :: t ->
    List.map ~f:t_to_bounds t
    |> List.fold ~f:Text_region.union ~init:(t_to_bounds h)
    |> fun x -> Some x
  | _ -> None

(** converts a zipper to the bounds of the current item *)
let to_bounds (MkLocation (current,_)) = 
  Text_region.to_bounds (t_to_bounds current)

(** updates the bounds of the zipper by a fixed offset *)
let update_bounds ~diff state =
  let mapper = Text_region.ast_bounds_mapper ~diff in
  (* update the bounds of a zipper by a fixed offset *)
  let rec update state =
    match state with
    | Signature_item si -> Signature_item (mapper.signature_item mapper si)
    | Structure_item si -> Structure_item (mapper.structure_item mapper si)
    | Value_binding vb -> Value_binding (mapper.value_binding mapper vb)
    | CoreType si  -> CoreType (mapper.typ mapper si)
    | Attribute si  -> Attribute (mapper.attribute mapper si)
    | Type_declaration tdcl -> Type_declaration (mapper.type_declaration mapper tdcl)
    | Pattern pat -> Pattern (mapper.pat mapper pat)
    | Expression expr -> Expression (mapper.expr mapper expr)
    | Text s -> Text (Text_region.shift_region s diff)
    | Wildcard s -> Wildcard (Text_region.shift_region s diff)
    | Sequence (None, l,c,r) ->
      let update_ls = List.map ~f:update in
      Sequence (None, update_ls l, update c, update_ls r)
    | Sequence (Some (region, ty), l,c,r) ->
      let update_ls = List.map ~f:update in
      let region = Text_region.shift_region region diff in
      Sequence (Some (region,ty), update_ls l, update c, update_ls r)
    | EmptySequence (region,ty) ->
      let region = Text_region.shift_region region diff in
      EmptySequence (region,ty)
  in
  update state

let t_sort (ls: t list) =
  ls
  |> List.map ~f:(fun l -> Text_region.column_start (t_to_bounds l), l)
  |> List.sort ~compare:(fun (l, _) (l', _) -> Int.compare l l')
  |> List.map ~f:(fun (_,l) -> l)

(** convert an arbitrary location delimited element into a text region *)
let  unwrap_loc ({ loc; _ }: 'a Asttypes.loc) =
  Text (Text_region.of_location loc)


let sort_t_list =
  let to_bounds vl = Text_region.column_start (t_to_bounds vl) in
  List.sort ~compare:(fun a b -> Int.compare (to_bounds a) (to_bounds b))

let rec unwrap_extensions ((loc, payload): Parsetree.extension) =
  let loc = unwrap_loc loc in
  match payload with
  | Parsetree.PStr si ->
    let si = List.map ~f:(fun v -> Structure_item v) si in
    let range =
      let sequence = Sequence (None, [], loc, si) in
      t_to_bounds sequence in
    let bounds = Some (range, Extension) in
    Sequence (bounds, [], loc, si)
  (* correct *)
  | Parsetree.PSig si ->
    let si = List.map ~f:(fun v -> Signature_item v) si in
    let range =
      let sequence = Sequence (None, [], loc, si) in
      t_to_bounds sequence in
    let bounds = Some (range, Extension) in
    Sequence (bounds, [], loc, si)
  (* correct *)
  | Parsetree.PTyp si ->
    let si = CoreType si in
    let range =
      let sequence = Sequence (None, [], loc, [si]) in
      t_to_bounds sequence in
    let bounds = Some (range, Extension) in
    Sequence (bounds, [], loc, [si])
  (* correct *)
  | Parsetree.PPat (pat, expr) ->
    let si =
      let expr = Option.map ~f:(fun e -> Expression e ) expr |> Option.to_list in
      (Pattern pat) :: (expr) in
    let range =
      let sequence = Sequence (None, [], loc, si) in
      t_to_bounds sequence in
    let bounds = Some (range, Extension) in
    Sequence (bounds, [], loc, si)
(* correct *)
and unwrap_binding_op ({ pbop_op; pbop_pat; pbop_exp; _ }: Parsetree.binding_op) =
  let loc = unwrap_loc pbop_op in
  let pat = Pattern pbop_pat in
  let exp = [Expression pbop_exp] in
  let range =
    let sequence = Sequence (None, [], loc, pat :: exp) in
    t_to_bounds sequence in
  let bounds = Some (range, BindingOp) in
  Sequence (bounds, [], loc, pat :: exp)
(* correct *)
and unwrap_type_declaration ({
    ptype_name;                 (* name of record *)
    ptype_params;               (* params of record *)
    ptype_cstrs;                (* constraints on record *)
    ptype_manifest;             (* manifest *)
    ptype_kind;                 (* fields *)
    _
  } : Parsetree.type_declaration) =
  let loc = unwrap_loc ptype_name in
  let params = List.map ptype_params ~f:(fun (cty, _) -> CoreType cty) in 
  let strs = List.map ptype_cstrs ~f:(fun (c1, c2, _loc) ->
      (* let range = Text_region.of_location loc in *)
      let c1 = CoreType c1 in
      let c2 = CoreType c2 in 
      let range =
        let sequence = Sequence (None, [], c1, [c2]) in
        t_to_bounds sequence
      in
      let bounds = Some (range, TypeConstraint) in
      Sequence (bounds, [], c1, [c2])
    ) in
  let o_man = Option.map ~f:(fun v -> CoreType v) ptype_manifest |> Option.to_list in
  let kind = unwrap_type_kind ptype_kind in
  let items = params @ strs @ o_man @ kind in
  let bounds =
    let range =
      let sequence = Sequence (None, [], loc, items) in
      t_to_bounds sequence
    in
    Some (range, TypeDeclaration) in
  Sequence (bounds, [], loc, items)
and unwrap_type_kind t : t list =
 match t with
| Parsetree.Ptype_abstract -> []
| Parsetree.Ptype_variant cdecl -> List.map ~f:unwrap_constructor_declaration cdecl
| Parsetree.Ptype_record ldecls -> List.map ~f:unwrap_label_declaration ldecls
| Parsetree.Ptype_open -> []
(* correct *)
and unwrap_module_type 
    ({ pmty_desc;
       _ (* pmty_loc; pmty_attributes *) } as mt: Parsetree.module_type) : _ option =
  let range =
    let iter,get = Text_region.ast_bounds_iterator () in
    iter.module_type iter mt ;
    get ()
  in 
  begin match pmty_desc with
    | Parsetree.Pmty_alias loc
    | Parsetree.Pmty_ident loc ->
      let loc = unwrap_loc loc in
      let bounds = Some (range, ModuleName) in 
      Some (Sequence (bounds, [], loc, []))
    | Parsetree.Pmty_signature (h :: t)  ->
      let current = Signature_item h in
      let above = List.map ~f:(fun x -> Signature_item x) t in 
      let bounds = Some (range, ModuleSignature) in 
      Some (Sequence (bounds, [], current, above))
    | Parsetree.Pmty_functor (omt, mt) ->
      let loc = Text (Text_region.of_location  mt.pmty_loc) (* unwrap_loc loc *) in
      let loc, o_mt = match omt with
        | Parsetree.Unit -> loc, []
        | Parsetree.Named (loc, mt) -> unwrap_loc loc, unwrap_module_type mt |> Option.to_list in
      let mt = unwrap_module_type mt |> Option.to_list in
      let items = o_mt @ mt in
      let bounds  = Some (range, ModuleTypeFunctor) in
      Some (Sequence (bounds, [], loc, items))
    | Parsetree.Pmty_with (mt, constraints) ->
      let mt = unwrap_module_type mt |> Option.to_list in
      let constraints = List.map ~f:unwrap_with_constraint constraints in
      let items = constraints @ mt  in
      begin
        match items with
        | [] -> None
        | h :: t  ->
          let bounds = Some (range, ModuleTypeWithConstraint) in
          Some (Sequence (bounds, [], h, t))
      end
    | Parsetree.Pmty_typeof mexpr ->
      let mexpr = unwrap_module_expr mexpr in
      mexpr
      |> Option.map ~f:(fun mexpr ->
          let bounds = Some (range, ModuleTypeOf) in
          Sequence (bounds, [], mexpr, []))
    | Parsetree.Pmty_extension ext ->
      let ext = unwrap_extensions ext in 
      let bounds = Some (range, Extension) in
      Some (Sequence (bounds, [], ext, []))
    | _ -> None
  end
(* correct *)
and unwrap_with_constraint (c: Parsetree.with_constraint) =
  match c with
  | Parsetree.Pwith_typesubst (loc, type_decl)
  | Parsetree.Pwith_type (loc, type_decl) ->
    let loc = unwrap_loc loc in
    let decl = [unwrap_type_declaration type_decl] in
    let range =
      let sequence = Sequence (None, [], loc, decl) in
      t_to_bounds sequence
    in
    let bounds = Some (range, WithConstraint) in
    Sequence (bounds, [], loc, decl)
  | Parsetree.Pwith_modsubst (loc1, loc2) 
  | Parsetree.Pwith_module (loc1, loc2) ->
    let loc1 = unwrap_loc loc1 in
    let loc2 = unwrap_loc loc2 in
    let range =
      let sequence = Sequence (None, [], loc1, [loc2]) in
      t_to_bounds sequence
    in
    let bounds = Some (range, WithConstraint) in
    Sequence (bounds, [], loc1, [loc2])
and unwrap_module_expr 
    ({ pmod_desc;
       (* pmod_loc=location; *)
       _ (* pmod_loc; pmod_attributes *) } as expr: Parsetree.module_expr)  =
  let range =
    let iter,get = Text_region.ast_bounds_iterator () in 
    iter.module_expr iter expr;
    get ()
  in 
  match pmod_desc with
  | Parsetree.Pmod_ident loc ->
    let bounds = Some (range,ModuleName) in
    let loc = unwrap_loc loc in
    Some (Sequence (bounds, [], loc, []))
  | Parsetree.Pmod_structure (m :: mt) ->
    let bounds = Some (range,ModuleStructure) in
    Some (Sequence (bounds, [], Structure_item m, List.map ~f:(fun x -> Structure_item x) mt))
  | Parsetree.Pmod_functor (o_mt, me) ->
    let bounds = Some (range,ModuleFunctor) in
    let loc, o_mt = match o_mt with
      | Parsetree.Unit -> Text (Text_region.of_location expr.pmod_loc), []
      | Parsetree.Named (loc, o_mt) ->
         unwrap_loc loc, unwrap_module_type o_mt |> Option.to_list
    in 
    let o_me = match unwrap_module_expr me with
      | None -> []
      | Some (Sequence (Some (_,ModuleFunctor), [], h, t)) -> h :: t
      | Some (t) -> [t]
    in
    let items = o_mt @ o_me in
    Some (Sequence (bounds, [], loc, items))
  | Parsetree.Pmod_apply (mexp1, mexp2) ->
    let bounds = Some (range,ModuleApply) in
    let expr = [mexp1;mexp2]
               |> List.map ~f:unwrap_module_expr
               |> List.map ~f:Option.to_list
               |> ListLabels.flatten
    in
    begin match expr with
      | h :: t -> Some (Sequence (bounds, [], h, t))
      | _ -> None
    end
  | Parsetree.Pmod_constraint (mexp1, mtyp1) ->
    let bounds = Some (range,ModuleConstraint) in
    let mexp = unwrap_module_expr mexp1 |> Option.to_list in
    let mtyp = unwrap_module_type mtyp1 |> Option.to_list in
    let items =  mtyp @ mexp in 
    begin match items with
      | h :: t -> Some (Sequence (bounds, [], h, t))
      | _ -> None
    end
  | Parsetree.Pmod_unpack expr ->
    let bounds = Some (range,ModuleUnpack) in
    let expr = Expression expr in
    Some (Sequence (bounds, [], expr, []))
  | Parsetree.Pmod_extension ext ->
    let bounds = Some (range,Extension) in
    let ext = unwrap_extensions ext in
    Some (Sequence (bounds, [], ext, []))
  | _ -> None
and unwrap_case ({ pc_lhs; pc_guard; pc_rhs }: Parsetree.case) =
  let items =
    let patt = [Pattern pc_lhs] in
    let guard = Option.map ~f:(fun v -> Expression v) pc_guard |> Option.to_list in
    let expr = [Expression pc_rhs] in
    patt @ guard @ expr in
  begin
    match items with
    | h :: t ->
      let range =
        let sequence = Sequence (None, [], h, t) in
        t_to_bounds sequence
      in
      let bounds = Some (range, Function) in 
      Some (Sequence (bounds, [], h, t))
    | [] -> None
  end
and unwrap_core_type ({ptyp_desc; _} as ty : Parsetree.core_type) : t = 
  let range = t_to_bounds (CoreType ty) in
  match ptyp_desc with
  | Parsetree.Ptyp_any -> CoreType ty
  | Parsetree.Ptyp_var _ -> CoreType ty
  | Parsetree.Ptyp_arrow (_, t1, t2) ->
    (* TODO: can't handle label as it doesn't have an explicit
       location - can generate custom locations from string length? *)
    begin match unwrap_core_type t2 with
      | Sequence (Some (_, Type TyArrow), below, current, after) ->
        Sequence (Some (range, Type TyArrow), [], CoreType t1, below @ current :: after)
      | _ ->
        Sequence (Some (range, Type TyArrow), [], CoreType t1, [CoreType t2])
    end
  | Parsetree.Ptyp_tuple [] -> CoreType ty
  | Parsetree.Ptyp_tuple (h :: t) -> 
    Sequence (Some (range, Type TyTuple), [], CoreType h, List.map ~f:(fun v -> CoreType v) t)
  | Parsetree.Ptyp_constr (name, tys) ->
    let name = unwrap_loc name in
    begin match tys with
      | [] -> Sequence (Some (range, Type TyConstr), [], name, [])
      | h :: t -> Sequence (
          Some (range, Type TyConstr), [],
          CoreType h,
          List.map ~f:(fun v  -> CoreType v) t @ [name])
    end
  | Parsetree.Ptyp_object ([], _) -> CoreType ty
  | Parsetree.Ptyp_object (h :: t, _) ->
    Sequence (Some (range, Type TyObj), [], unwrap_object_field h, List.map ~f:unwrap_object_field t)
  | Parsetree.Ptyp_class (name, tys) ->
    let name = unwrap_loc name in
    Sequence (Some (range, Type TyClass), [], name, List.map ~f:(fun v -> CoreType v) tys)
  | Parsetree.Ptyp_alias (ty, _) ->
    Sequence (Some (range, Type TyAlias), [], CoreType ty, [])
  | Parsetree.Ptyp_variant ([], _, _) -> CoreType ty
  | Parsetree.Ptyp_variant (h :: t, _, _) ->
    Sequence (Some (range, Type TyVariant), [], unwrap_record_field h, List.map ~f:unwrap_record_field t)    
  | Parsetree.Ptyp_poly ([], cty) ->
    Sequence (Some (range, Type TyPoly), [], CoreType cty, []) 
  | Parsetree.Ptyp_poly (h :: t, cty) ->
    Sequence (Some (range, Type TyPoly), [], unwrap_loc h, List.map ~f:unwrap_loc t @ [CoreType cty]) 
  | Parsetree.Ptyp_package (name, pckg_fields) ->
    let name = unwrap_loc name in
    Sequence (Some (range, Type TyPackage), [], name, List.map ~f:unwrap_package_field pckg_fields) 
  | Parsetree.Ptyp_extension ext ->
    Sequence (Some (range, Type TyExtension), [], unwrap_extensions ext, [])
and unwrap_package_field (name, cty) : t =
  let name = unwrap_loc name in
  let range = t_to_bounds @@ Sequence (None, [], name, [CoreType cty]) in
  Sequence (Some (range, Type TyPackageField), [], name, [CoreType cty])
and unwrap_record_field { prf_desc; _ } : t =
  match prf_desc with
  | Parsetree.Rtag (name, _, tys) ->
    let name = unwrap_loc name in
    let tys = List.map ~f:(fun v -> CoreType v) tys in
    let range = t_to_bounds @@ Sequence (None, [], name, tys) in
    Sequence (Some (range, Type TyRowField), [], name, tys)
  | Parsetree.Rinherit cty ->
    let range = t_to_bounds @@ Sequence (None, [], CoreType cty, []) in
    Sequence (Some (range, Type TyRowField), [], CoreType cty, [])
and unwrap_object_field ({ pof_desc; _ }) : t =
  match pof_desc with
  | Parsetree.Otag (name, ty) ->
    let name = unwrap_loc name in
    let range = t_to_bounds @@ Sequence (None, [], name, [CoreType ty]) in
    Sequence (Some (range, Type TyObjectField), [], name, [CoreType ty])
  | Parsetree.Oinherit ty ->
    let range = t_to_bounds @@ Sequence (None, [], CoreType ty, []) in
    Sequence (Some (range, Type TyObjectField), [], CoreType ty, [])    
and unwrap_pattern ({ppat_desc; _} as pat : Parsetree.pattern) : t = 
  let range = t_to_bounds (Pattern pat) in
  match ppat_desc with
  | Parsetree.Ppat_constant _ -> Pattern pat   (* 1,  *)
  | Parsetree.Ppat_var _ -> Pattern pat (* x *)
  | Parsetree.Ppat_any -> Wildcard range (* _ *)
  | Parsetree.Ppat_interval (_, _) ->
    (* TODO: add support for generating custom locations from string lengths? *)
    Pattern pat (* 'a' .. 'z' *)
  | Parsetree.Ppat_alias (pat, name) ->
    let name = unwrap_loc name in
    Sequence (Some (range, Pattern), [], Pattern pat, [name])
  (* P as 'a *)
  | Parsetree.Ppat_tuple [] -> Pattern pat
  | Parsetree.Ppat_tuple (h :: t) ->
    Sequence (Some (range, Pattern), [], Pattern h, List.map ~f:(fun v -> Pattern v) t)
  (* (p1, ..., pn) (n >= 2) *)
  | Parsetree.Ppat_construct (cons, pat) ->
    let cons = unwrap_loc cons in
    begin match pat with
      | None -> cons
      | Some pat -> Sequence (Some (range, Pattern), [], cons, [Pattern pat])
    end
  (* C, C P, C (P1, ..., Pn) *)
  | Parsetree.Ppat_variant (_, pat) ->
    (* TODO: add support for generating custom locations from string lengths *)
    begin match pat with
      | None -> Sequence (Some (range, Pattern), [], Text range, [])
      | Some pat -> Pattern pat
    end   (* `A, `A P *)
  | Parsetree.Ppat_record ([], _) -> Pattern pat
  | Parsetree.Ppat_record (h :: t, _) ->
    Sequence (Some (range, Pattern), [], unwrap_record_binding h, List.map ~f:unwrap_record_binding t)
  (* { l1=P1; ...; ln=Pn } *)
  | Parsetree.Ppat_array [] -> Pattern pat
  | Parsetree.Ppat_array (h :: t) ->
    Sequence (Some (range, Pattern), [], Pattern h, List.map ~f:(fun v -> Pattern v) t)
  (* [| P1; ...; Pn |]  *)
  | Parsetree.Ppat_or (p1, p2) ->
    Sequence (Some (range, Pattern), [], Pattern p1, [Pattern p2])
  (* P1 | P2 *)
  | Parsetree.Ppat_constraint (pat, ty) ->
    Sequence (Some (range, Pattern), [], Pattern pat, [CoreType ty])
  (* (P : T) *)
  | Parsetree.Ppat_type _ -> Pattern pat            (* #canst *)
  | Parsetree.Ppat_lazy pat ->
    Sequence (Some (range, Pattern), [], Pattern pat, [])
  (* lazy P *)
  | Parsetree.Ppat_unpack name ->
    let name = unwrap_loc name in
    Sequence (Some (range, Pattern), [], name, [])
  (* (module P) *)
  | Parsetree.Ppat_exception pat ->
    Sequence (Some (range, Pattern), [], Pattern pat, [])
  (* exception P *)
  | Parsetree.Ppat_extension ext ->
    Sequence (Some (range, Pattern), [], unwrap_extensions ext, [])
  (* [%id] *)
  | Parsetree.Ppat_open (name, pat) ->
    let name = unwrap_loc name in
    Sequence (Some (range, Pattern), [name], Pattern pat, [])
(* M.(P) *)
and unwrap_record_binding ((name: Longident.t Location.loc), (pat: Parsetree.pattern)) =
  let name = unwrap_loc name in
  let pat = Pattern pat in
  let range = t_to_bounds (Sequence (None, [], name, [pat])) in
  Sequence (Some (range, Pattern), [], name, [pat])
and unwrap_expr ({ pexp_desc; _ } as expr: Parsetree.expression) =
  let range = 
    t_to_bounds (Expression expr) in
  match pexp_desc with
  (* | Parsetree.Pexp_ident _ -> (??) *)
  (* | Parsetree.Pexp_constant _ -> (??) *)
  | Parsetree.Pexp_let (_, vbs, expr) ->
    let vbs = List.map ~f:(fun vb -> Value_binding vb) vbs in
    (* consecutive let bindings and sequences are flattened out *)
    let expr,t = match unwrap_expr expr with
      | Sequence (Some (_,LetBinding), [], h, t)  -> h, t
      | Sequence (Some (_,LetModule), [], h, t)  -> h, t
      | Sequence (Some (_,LetException), [], h, t)  -> h, t
      | Sequence (Some (_,BindingOp), [], h, t)  -> h, t
      | Sequence (Some (_,Seq), [], h, t)  -> h, t
      | Sequence (Some (_,LetOp), [], h, t)  -> h, t
      | Sequence (Some (_,Extension), [], h, t)  -> h, t
      | _ -> Expression expr,[] in
    let bounds = Some (range, LetBinding) in
    begin
      match vbs with
      | v :: vbs -> Sequence (bounds, [], v, vbs @ expr :: t)
      | [] -> Sequence (bounds, [], expr, t)
    end 
  | Parsetree.Pexp_letmodule (loc, mexpr, expr) ->
    let loc = unwrap_loc loc in 
    let mexpr =  unwrap_module_expr mexpr  in
    let expr = match unwrap_expr expr with
      | Sequence (Some (_,LetBinding), [], h, t)  -> h :: t
      | Sequence (Some (_,LetModule), [], h, t)  -> h :: t
      | Sequence (Some (_,LetException), [], h, t)  -> h :: t
      | Sequence (Some (_,BindingOp), [], h, t)  -> h :: t
      | Sequence (Some (_,Seq), [], h, t)  -> h :: t
      | Sequence (Some (_,LetOp), [], h, t)  -> h :: t
      | Sequence (Some (_,Extension), [], h, t)  -> h :: t
      | _ -> [Expression expr] in
    let bounds = Some (range, LetModule) in
    let modbind =
      match mexpr with
      | None -> loc
      | Some mexpr ->
        let range =
          let sequence = Sequence (None, [], loc, [mexpr]) in 
          t_to_bounds sequence
        in
        let bounds = Some (range, LetModuleBinding) in 
        Sequence (bounds, [], loc, [mexpr]) in 
    Sequence (bounds, [], modbind, expr)
  | Parsetree.Pexp_letexception (cons, expr) ->
    let expn = unwrap_extension_constructor cons in
    let expr = match unwrap_expr expr with
      | Sequence (Some (_,LetBinding), [], h, t)  -> h :: t
      | Sequence (Some (_,LetModule), [], h, t)  -> h :: t
      | Sequence (Some (_,LetException), [], h, t)  -> h :: t
      | Sequence (Some (_,BindingOp), [], h, t)  -> h :: t
      | Sequence (Some (_,Seq), [], h, t)  -> h :: t
      | Sequence (Some (_,LetOp), [], h, t)  -> h :: t
      | Sequence (Some (_,Extension), [], h, t)  -> h :: t
      | _ -> [Expression expr] in
    let bounds = Some (range, LetException) in
    Sequence (bounds, [], expn, expr)
  | Parsetree.Pexp_letop { let_; ands; body } ->
    let current = unwrap_binding_op let_ in
    let right1 = List.map ~f:unwrap_binding_op ands in
    let right2 =
      let sub_expression = unwrap_expr body in
      match sub_expression with
      | Sequence (Some (_,LetBinding), [], h, t)  -> h ::  t
      | Sequence (Some (_,LetModule), [], h, t)  -> h ::  t
      | Sequence (Some (_,LetException), [], h, t)  -> h :: t
      | Sequence (Some (_,LetOp), [], h, t)  -> h :: t
      | Sequence (Some (_,BindingOp), [], h, t)  -> h :: t
      | Sequence (Some (_,Seq), [], h, t)  -> h :: t
      | Sequence (Some (_,Extension), [], h, t)  -> h :: t
      | _ -> [Expression body] in
    let bounds = Some (range, LetOp) in
    Sequence (bounds, [], current, right1 @ right2)    
  | Parsetree.Pexp_function (cases) ->
    let cases = List.filter_map ~f:unwrap_case cases in
    let bounds = Some (range, Function) in
    begin
      match cases with
      | [] -> Expression expr
      | h :: t -> Sequence (bounds, [], h, t)
    end
  | Parsetree.Pexp_newtype (loc, expr) ->
    let loc = unwrap_loc loc in
    let expr = match unwrap_expr expr with
      | Sequence (Some (_,Lambda), [], h, t)  -> h :: t
      | Sequence (Some (_,LambdaType), [], h, t)  -> h :: t
      | Sequence (Some (_,Constraint), [], h, t)  -> h :: t
      (* intermediate *)
      | _ -> [Expression expr]
    in
    let bounds = Some (range, LambdaType) in
    Sequence (bounds, [], loc, expr)
  | Parsetree.Pexp_fun (_, o_deflt, pat, expr) ->
    let items =
      let dflt = Option.map ~f:(fun e -> Expression e) o_deflt
                 |> Option.to_list in
      let pat = [Pattern pat] in
      let expr = match unwrap_expr expr with
        | Sequence (Some (_,Lambda), [], h, t)  -> h :: t
        | Sequence (Some (_,LambdaType), [], h, t)  -> h :: t
        | Sequence (Some (_,Constraint), [], h, t)  -> h :: t
        (* intermediate *)
        | _ -> [Expression expr]
      in
      pat @ dflt @ expr in 
    let bounds = Some (range, Lambda) in
    begin
      match items with
      | [] -> assert false
      | h :: t -> Sequence (bounds, [], h , t)
    end
  | Parsetree.Pexp_apply (expr, elems) ->
    let expr = Expression expr in
    let elems = List.map ~f:(fun (_,e) -> Expression e) elems in
    let bounds  = Some (range, Apply) in
    let items = t_sort (expr :: elems) in 
    begin
      match items with
      | [] -> assert false
      | h :: t -> Sequence (bounds, [], h, t)
    end
  | Parsetree.Pexp_match (expr, cases) ->
    let expr = Expression expr in
    let cases = List.filter_map ~f:unwrap_case cases in
    Sequence (Some (range, Match), [], expr, cases)
  | Parsetree.Pexp_try (expr, cases) ->
    let expr = Expression expr in
    let cases = List.filter_map ~f:unwrap_case cases in
    Sequence (Some (range, Try), [], expr, cases)
  | Parsetree.Pexp_tuple (e :: exprs) ->
    let expr = Expression e in
    let exprs = List.map ~f:(fun e -> Expression e) exprs in
    let bounds = Some (range, Tuple) in
    Sequence (bounds, [], expr, exprs)
  | Parsetree.Pexp_construct (_, Some expr) ->
    let expr = Expression expr in
    let bounds = Some (range, Constructor) in 
    Sequence (bounds, [], expr, [])
  | Parsetree.Pexp_variant (_, Some expr) ->
    let expr = Expression expr in
    let bounds = Some (range, Variant) in 
    Sequence (bounds, [], expr, [])
  | Parsetree.Pexp_record (exp_list, exp) ->
    let exps = List.map ~f:(fun (vl, exp) ->
        let vl = unwrap_loc vl in
        let exp = Expression exp in 
        let range = 
          let sequence = Sequence (None, [], vl, [exp]) in 
          t_to_bounds sequence in
        let bounds = Some (range, RecordField) in
        Sequence (bounds, [], vl, [exp])
      ) exp_list in
    let exp = Option.map ~f:(fun v -> Expression v) exp |> Option.to_list in
    let items = exps @ exp in
    let bounds = Some (range, Record) in     
    begin
      match items with
      | h :: t -> Sequence (bounds, [], h, t)
      | [] -> Expression expr
    end
  | Parsetree.Pexp_field (expr, loc) ->
    let expr = Expression expr in
    let loc = unwrap_loc loc in
    let bounds = Some (range, GetField) in
    Sequence (bounds, [], expr, [loc])
  | Parsetree.Pexp_setfield (e1, loc, e2) ->
    let e1 = Expression e1 in
    let loc = unwrap_loc loc in
    let e2 = Expression e2 in
    let bounds = Some (range, SetField) in
    Sequence (bounds, [], e1, [loc; e2])
  | Parsetree.Pexp_array (h :: t) ->
    let expr = Expression h in
    let t = List.map ~f:(fun v -> Expression v) t in
    let bounds = Some (range, Array) in
    Sequence (bounds, [], expr, t)
  | Parsetree.Pexp_ifthenelse (e1, e2, oe3) ->
    let e1 = Expression e1 in
    let e2 = Expression e2 in
    let e3 = Option.map oe3 ~f:(fun e -> Expression e) |> Option.to_list in
    let bounds = Some (range, IfThenElse) in
    Sequence (bounds, [], e1, e2::e3)
  | Parsetree.Pexp_sequence (e1, e2) ->
    let e1 = Expression e1 in
    let e2 =
      let sub_expression = unwrap_expr e2 in
      match sub_expression with
      | Sequence (Some (_,LetBinding), [], h, t)  -> h ::  t
      | Sequence (Some (_,LetModule), [], h, t)  -> h ::  t
      | Sequence (Some (_,BindingOp), [], h, t)  -> h :: t
      | Sequence (Some (_,Seq), [], h, t)  -> h :: t
      | Sequence (Some (_,LetOp), [], h, t)  -> h :: t
      | Sequence (Some (_,Extension), [], h, t)  -> h :: t
      | _ -> [Expression e2] in
    let bounds = Some (range, Seq) in
    Sequence (bounds, [], e1, e2)
  | Parsetree.Pexp_while (e1, e2) ->
    let e1 = Expression e1 in
    let e2 = Expression e2 in
    let bounds = Some (range, While) in
    Sequence (bounds, [], e1, [e2])
  | Parsetree.Pexp_for (pat, e1, e2, _, e3) ->
    let pat = Pattern pat in
    let e1 = Expression e1 in
    let e2 = Expression e2 in
    let e3 = Expression e3 in
    let bounds = Some (range, For) in
    Sequence (bounds, [], pat, [e1;e2;e3])
  | Parsetree.Pexp_constraint (exp, coretype) ->
    let expr = Expression exp in
    let coretype = CoreType coretype in
    let bounds = Some (range, Constraint) in
    Sequence (bounds, [], coretype, [expr])
  | Parsetree.Pexp_coerce (e1, c1, c2) ->
    let e1 = Expression e1 in
    let c1 = Option.map ~f:(fun v -> CoreType v) c1 |> Option.to_list in
    let c2 =  [CoreType c2] in
    let bounds = Some (range, Coerce) in
    Sequence (bounds, [], e1, c1 @ c2)
  | Parsetree.Pexp_send (e1, loc) ->
    let e1 = Expression e1 in
    let loc = unwrap_loc loc in
    let bounds = Some (range, Send) in
    Sequence (bounds, [], e1, [loc])
  | Parsetree.Pexp_new location ->
    let location = unwrap_loc location in
    let bounds = Some (range, New) in
    Sequence (bounds, [], location, [])
  | Parsetree.Pexp_setinstvar (loc, e1) ->
    let loc = unwrap_loc loc in
    let e1 = Expression e1 in
    let bounds = Some (range, AssignField) in
    Sequence (bounds, [], loc, [e1])
  | Parsetree.Pexp_override ls ->
    let items = List.map ~f:(fun (loc,expr) ->
        let loc = unwrap_loc loc in
        let expr  = Expression expr in
        let range =
          let sequence = Sequence (None, [], loc, [expr]) in
          t_to_bounds sequence in
        let bounds = Some (range, OverrideField) in
        Sequence (bounds, [], loc, [expr])
      ) ls in
    let bounds = Some (range, Override) in
    begin
      match items with
      | h :: t -> Sequence (bounds, [], h, t)
      | [] -> Expression expr
    end
  | Parsetree.Pexp_assert expression ->
    Sequence (Some (range, Assert), [], Expression expression, [])
  | Parsetree.Pexp_lazy expr -> 
    Sequence (Some (range, Lazy), [], Expression expr, [])
  | Parsetree.Pexp_poly (expr, cty) ->
    let expr = Expression expr in
    let cty = Option.map ~f:(fun ct -> CoreType ct) cty
              |> Option.to_list in
    let bounds = Some (range, Poly) in
    Sequence (bounds, [], expr, cty)
  | Parsetree.Pexp_pack mexpr ->
    let mexpr = unwrap_module_expr mexpr in
    begin
      match mexpr with
      | None -> Expression expr
      | Some mexpr ->
        Sequence (Some (range, PackModule), [], mexpr, [])
    end
  | Parsetree.Pexp_open ({ popen_expr; _ }, expr) ->
    let mod_expr = unwrap_module_expr popen_expr in
    let expr = Expression expr in
    begin
      match mod_expr with
      | Some mod_expr -> Sequence (Some (range, ModuleOpen), [], mod_expr, [expr])
      | None -> Sequence (Some (range, ModuleOpen), [], expr, [])
    end
  | Parsetree.Pexp_extension ext ->
    unwrap_extensions ext
  | Parsetree.Pexp_object cs ->
    let bounds = Some (range, ClassObject) in
    let cs = unwrap_class_structure cs in
    Sequence (bounds, [], cs, [])
  | _ -> Expression expr
(* | Parsetree.Pexp_unreachable -> (??) *)
and unwrap_class_structure ({ pcstr_self; pcstr_fields }:Parsetree.class_structure) =
  let pat = Pattern pcstr_self in
  let fields = List.map ~f:unwrap_class_fields pcstr_fields in
  let range =
    let sequence = Sequence (None, [], pat, fields)  in
    t_to_bounds sequence
  in
  let bounds = Some (range, ClassStructure) in
  Sequence (bounds, [], pat, fields)
and unwrap_class_fields ({ pcf_desc; pcf_loc; _ (* pcf_loc; pcf_attributes *) }:Parsetree.class_field) =
  let range = Text_region.of_location pcf_loc in 
  match pcf_desc with
  | Parsetree.Pcf_inherit (_, c_e, name) ->
    let c_e = unwrap_class_expr c_e in
    let name = Option.map ~f:unwrap_loc name |> Option.to_list in
    Sequence (Some (range, ClassInherit), [], c_e, name)
  | Parsetree.Pcf_val (name, _, cfk) ->
    let name = unwrap_loc name in
    let cf = unwrap_class_field_kind cfk in
    Sequence (Some (range, ValueDeclaration), [], name, [cf])
  | Parsetree.Pcf_method (name, _, cfk) ->
    let name = unwrap_loc name in
    let cfk = unwrap_class_field_kind cfk in
    let bounds = Some (range, MethodDeclaration) in
    Sequence (bounds, [], name, [cfk])
  | Parsetree.Pcf_constraint (c1,c2) ->
    let c1 = CoreType c1 in 
    let c2 = CoreType c2 in 
    let bounds = Some (range, ClassConstraint) in
    Sequence (bounds, [], c1, [c2])
  | Parsetree.Pcf_initializer expr ->
    let expr = Expression expr in
    let bounds = Some (range, ClassInitializer) in
    Sequence (bounds, [], expr, [])
  | Parsetree.Pcf_attribute attr ->
    let attr = Attribute attr in
    let bounds = Some (range, ClassField) in
    Sequence (bounds, [], attr, [])
  | Parsetree.Pcf_extension ext -> 
    let ext = unwrap_extensions ext in
    let bounds = Some (range, ClassField) in
    Sequence (bounds, [], ext, [])
and unwrap_class_field_kind (cfk: Parsetree.class_field_kind) =
  match cfk with
  | Parsetree.Cfk_virtual ct -> CoreType ct
  | Parsetree.Cfk_concrete (_, expr) -> unwrap_expr expr
and unwrap_class_expr ({ pcl_desc;  pcl_loc=loc; _ }: Parsetree.class_expr) =
  let range = Text_region.of_location loc in
  match pcl_desc with
  | Parsetree.Pcl_constr (name, types) ->
    let loc = unwrap_loc name in 
    let types = List.map ~f:(fun ct -> CoreType ct) types in
    let bounds = Some (range, ClassConstructor) in 
    Sequence (bounds, [], loc, types)
  | Parsetree.Pcl_structure cs ->
    let class_structure = unwrap_class_structure cs in 
    let bounds = Some (range, ClassObject) in
    Sequence (bounds, [], class_structure, [])
  | Parsetree.Pcl_fun (_, oex1, pat, c_exp) ->
    let oex1 = Option.map ~f:(fun e -> Expression e) oex1 |> Option.to_list in
    let pat = Pattern pat in
    let c_exp = match unwrap_class_expr c_exp with
      | Sequence (Some (_, Lambda), [], h, t) -> h :: t
      | Sequence (Some (_,LambdaType), [], h, t)  -> h :: t
      | Sequence (Some (_, Constraint), [], h, t) -> h :: t
      | v -> [v] in 
    let items = oex1 @ pat :: c_exp |> t_sort in
    begin
      match items with
      | [] -> assert false
      | h :: t -> Sequence (Some (range, Lambda), [], h, t)
    end
  | Parsetree.Pcl_apply (expr, elems) ->
    let expr = unwrap_class_expr expr in
    let elems = List.map ~f:(fun (_,e) -> Expression e) elems in
    let bounds  = Some (range, Apply) in
    let items = t_sort (expr :: elems) in 
    begin
      match items with
      | [] -> assert false
      | h :: t -> Sequence (bounds, [], h, t)
    end
  | Parsetree.Pcl_let (_, vbs, expr) -> 
    let vbs = List.map ~f:(fun vb -> Value_binding vb) vbs in
    let expr,t = match unwrap_class_expr expr with
      | Sequence (Some (_,LetBinding), [], h, t)  -> h, t
      | Sequence (Some (_,LetModule), [], h, t)  -> h, t
      | Sequence (Some (_,BindingOp), [], h, t)  -> h, t
      | Sequence (Some (_,Seq), [], h, t)  -> h, t
      | Sequence (Some (_,LetOp), [], h, t)  -> h, t
      | Sequence (Some (_,Extension), [], h, t)  -> h, t
      | e -> e,[] in
    let bounds = Some (range, LetBinding) in
    begin
      match vbs with
      | v :: vbs -> Sequence (bounds, [], v, vbs @ expr :: t)
      | [] -> Sequence (bounds, [], expr, t)
    end 
  | Parsetree.Pcl_constraint (exp, coretype) -> 
    let expr = unwrap_class_expr exp in
    let coretype = unwrap_class_type coretype in
    let bounds = Some (range, Constraint) in
    Sequence (bounds, [], coretype, [expr])
  | Parsetree.Pcl_extension ext ->
    let ext = unwrap_extensions ext in
    Sequence (Some (range, Extension), [], ext, [])
  | Parsetree.Pcl_open (op, cexp) ->
    let op = unwrap_open_desc op in
    let cexp = unwrap_class_expr cexp in
    let bounds = Some (range, ClassOpen) in
    Sequence (bounds, [], op, [cexp])
and unwrap_open_desc ({ popen_expr; (* popen_override; *) 
                        _  }: Parsetree.open_description) =
  let loc = unwrap_loc popen_expr in
  let range =
    let sequence = Sequence (None, [], loc, [])  in
    t_to_bounds sequence in
  let bounds = Some (range, ModuleOpen) in
  Sequence (bounds, [], loc, [])
and unwrap_class_type ({ pcty_desc; pcty_loc; _ }: Parsetree.class_type) =
  let range = Text_region.of_location pcty_loc in 
  match pcty_desc with
  | Parsetree.Pcty_constr (name, types) -> 
    let loc = unwrap_loc name in 
    let types = List.map ~f:(fun ct -> CoreType ct) types in
    let bounds = Some (range, ClassConstructor) in 
    Sequence (bounds, [], loc, types)
  | Parsetree.Pcty_signature cs ->
    let cs = unwrap_class_signature cs in
    let bounds = Some (range, ClassObjectType) in
    Sequence (bounds, [], cs, [])
  | Parsetree.Pcty_arrow (_, ty, cs) ->
    let ty = CoreType ty in
    let expr = match unwrap_class_type cs with
      | Sequence (Some (_, ClassArrow), [], h, t) -> h :: t
      | v -> [v] in
    let bounds = Some (range, ClassArrow) in
    Sequence (bounds, [], ty, expr)
  | Parsetree.Pcty_extension ext ->
    let ext = unwrap_extensions ext in
    let bounds = Some (range, Extension) in
    Sequence (bounds, [], ext, [])
  | Parsetree.Pcty_open (od, ct) ->
    let od = unwrap_open_desc od in
    let ct = unwrap_class_type ct in
    let bounds = Some (range, ClassOpen) in
    Sequence (bounds, [], od, [ct])
and unwrap_class_signature ({ pcsig_self; pcsig_fields }: Parsetree.class_signature) =
  let ct = CoreType pcsig_self in
  let fields = List.map ~f:unwrap_class_field_type pcsig_fields in
  let range =
    let sequence = Sequence (None, [], ct, fields) in
    t_to_bounds sequence
  in
  let bounds = Some (range, ClassSignature) in
  Sequence (bounds, [], ct, fields)
and unwrap_class_field_type ({ pctf_desc; pctf_loc; _ }: Parsetree.class_type_field) =
  let range = Text_region.of_location pctf_loc in
  match pctf_desc with
  | Parsetree.Pctf_inherit ct ->
    let ct = unwrap_class_type ct in
    let bounds = Some (range, ClassInherit) in
    Sequence (bounds, [], ct, [])
  | Parsetree.Pctf_val (name, _, _, ct) ->
    let bounds = Some (range, ValueDeclaration) in
    let loc = unwrap_loc name in 
    let ct = CoreType ct in
    Sequence (bounds, [], loc, [ct])
  | Parsetree.Pctf_method (name, _, _, ct) ->
    let bounds = Some (range, MethodType) in
    let loc = unwrap_loc name in
    let ct = CoreType ct in
    Sequence (bounds, [], loc, [ct])
  | Parsetree.Pctf_constraint (ct1,ct2) ->
    let bounds = Some (range, ClassConstraint) in
    let ct1 = CoreType ct1 in 
    let ct2 = CoreType ct2 in
    Sequence (bounds, [], ct1, [ct2])
  | Parsetree.Pctf_attribute attr ->
    let attr = Attribute attr in
    let bounds = Some (range, ClassTypeField) in
    Sequence (bounds, [], attr, [])
  | Parsetree.Pctf_extension extension ->
    let ext = unwrap_extensions extension in
    let bounds = Some (range, ClassTypeField) in
    Sequence (bounds, [], ext, [])
and unwrap_module_binding ({ pmb_name=loc; pmb_expr; _ }: Parsetree.module_binding) =
  let loc  = unwrap_loc loc in
  let pmb_expr = unwrap_module_expr pmb_expr |> Option.to_list in
  let bounds =
    let range =
      let sequence = Sequence (None, [], loc, pmb_expr) in
      t_to_bounds sequence
    in
    Some (range, ModuleBinding)
  in
  Sequence (bounds, [], loc, pmb_expr)
and unwrap_module_declaration ({ pmd_name=loc; pmd_type; _ (* pmd_loc *) }:
                                 Parsetree.module_declaration) =
  let loc = unwrap_loc loc in
  let md_type = unwrap_module_type pmd_type |> Option.to_list in
  let range =
    let sequence = Sequence (None, [], loc, md_type)  in
    t_to_bounds sequence
  in 
  let bounds = Some (range,ModuleConstraint) in
  Sequence (bounds, [], loc, md_type)
and unwrap_value_description ({ pval_name; pval_type; _ }: Parsetree.value_description) =
  let loc = unwrap_loc pval_name in
  let ty = CoreType pval_type in
  let range =
    let sequence = Sequence (None, [], loc, [ty]) in
    t_to_bounds sequence
  in
  let bounds = Some (range, ValueDeclaration) in
  Sequence (bounds, [], loc, [ty])
and unwrap_extension_constructor ({ pext_name=name;
                                    pext_kind=kind;
                                    _ }: Parsetree.extension_constructor) =
  let name = unwrap_loc name in
  let kind = match kind with
    | Parsetree.Pext_decl (cargs, cty) ->
      unwrap_constructor_arguments cargs
      @ (Option.map ~f:(fun cty -> CoreType cty ) cty |> Option.to_list)
    | Parsetree.Pext_rebind name -> [unwrap_loc name] in
  let range =
    let sequence = Sequence (None, [], name, kind) in
    t_to_bounds sequence
  in
  let bounds = Some (range, TypeExtensionCase) in 
  Sequence (bounds, [], name, kind)
and unwrap_exception ?range ({
    ptyexn_constructor;
    ptyexn_loc;
    _ }: Parsetree.type_exception) =
  let range = match range with
    | None -> Text_region.of_location ptyexn_loc
    | Some v  -> v in 
  let cons = unwrap_extension_constructor ptyexn_constructor in
  let bounds = Some (range, ExceptionDefinition) in
  Sequence (bounds, [], cons, [])
and unwrap_constructor_arguments (cargs: Parsetree.constructor_arguments) =
  match cargs with
  | Parsetree.Pcstr_tuple ctypes ->
    List.map ~f:(fun ct -> CoreType ct) ctypes
  | Parsetree.Pcstr_record labels ->
    List.map ~f:unwrap_label_declaration labels
and unwrap_label_declaration ({ pld_name;  pld_type; _ }: Parsetree.label_declaration) =
  let name = unwrap_loc pld_name in
  let ty = CoreType pld_type in
  let range =
    let sequence = Sequence (None, [], name, [ty]) in
    t_to_bounds sequence
  in
  Sequence (Some (range, LabelSpecification), [], name, [ty])
and unwrap_constructor_declaration { pcd_name; pcd_args; pcd_res; _ } : t =
  let name = unwrap_loc pcd_name in
  let res = Option.map ~f:(fun v -> CoreType v) pcd_res |> Option.to_list in
  let args = unwrap_constructor_arguments pcd_args in
  let items = args @ res in
  let range = t_to_bounds @@ Sequence (None, [], name, items) in
  Sequence (Some (range, ConstructorDefinition), [], name, items)
and t_descend ?range t =
  let range = Option.value range ~default:(t_to_bounds t) in
  match t with
  | Type_declaration tdecl -> unwrap_type_declaration tdecl
  | CoreType ty -> unwrap_core_type ty
  | Expression expr -> unwrap_expr expr
  | Pattern pat -> unwrap_pattern pat
  | Value_binding { pvb_pat; pvb_expr; _ } ->
    let current = Pattern pvb_pat in
    let right = match unwrap_expr pvb_expr with
      | Sequence (Some (_,Lambda), [], h, t)  -> h :: t
      | Sequence (Some (_,LambdaType), [], h, t)  -> h :: t
      | Sequence (Some (_,Constraint), [], h, t)  -> h :: t
      | _ -> [Expression pvb_expr] in
    let bounds = Some (range, ValueBinding) in 
    Sequence (bounds, [], current, right)
  | Signature_item ({ psig_desc; _ } as si) ->
    begin match psig_desc with
      | Parsetree.Psig_value {pval_name;pval_type; _} ->
        let loc = unwrap_loc pval_name in
        let items = [CoreType pval_type] in
        let bounds = Some (range, ValueDeclaration) in
        Sequence (bounds, [], loc, items)
      (* val x: T *)
      | Parsetree.Psig_typesubst fields
      (* type t1 = ... and tn = ... *)
      | Parsetree.Psig_type (_, fields) ->
        begin
          match List.map ~f:unwrap_type_declaration fields with
          | h:: t -> Sequence (Some (range, TypeDefinition), [], h, t)
          | [] -> Signature_item si
        end
      (* type t1 = ... and tn = ... *)
      | Parsetree.Psig_module {
          pmd_name=loc;
          pmd_type=pmd_type;
          (* pmd_attributes;
           * pmd_loc *) _ } ->
        let loc = unwrap_loc loc in
        let items = unwrap_module_type pmd_type |> Option.to_list in
        let bounds = Some (range, ModuleDeclaration) in 
        Sequence (bounds, [], loc, items)
      | Parsetree.Psig_modsubst { pms_attributes=l::ls; _ } ->
        let bounds = Some (range, ModuleSubst) in
        let current = Attribute l in
        let right = List.map ~f:(fun v -> Attribute v) ls in
        Sequence (bounds, [], current, right)
      | Parsetree.Psig_recmodule ls ->
        let elems  = List.map ~f:unwrap_module_declaration ls in
        let bounds = Some (range, ModuleDeclaration) in
        begin
          match elems with
          | current::right -> Sequence (bounds, [], current, right)
          | [] -> Signature_item si
        end
      | Parsetree.Psig_include { pincl_mod=ty; (* pincl_loc; *) pincl_attributes=attrs; _ } 
      | Parsetree.Psig_modtype {  pmtd_type=Some ty; pmtd_attributes=attrs; _ (* pmtd_loc *) } ->
        let current = unwrap_module_type ty in
        let attributes = List.map ~f:(fun a -> Attribute a) attrs in
        let bounds = Some (range, ModuleTypeDefinition) in
        begin
          match current,attributes with
          | Some current, left -> Sequence (bounds, left, current,[])
          | None, h :: t -> Sequence (bounds, [], h, t)
          | _ -> Signature_item si
        end
      | Parsetree.Psig_open
          { (* popen_expr; popen_override; popen_loc; *) popen_attributes=l::ls; _ } ->
        let current = Attribute l in
        let right = List.map ~f:(fun v -> Attribute v) ls in
        let bounds = Some (range, ModuleOpen) in
        Sequence (bounds, [], current, right)
      | Parsetree.Psig_attribute attr -> Attribute attr
      | Parsetree.Psig_exception exc -> unwrap_exception ~range exc (* type exn *)
      | Parsetree.Psig_typext {
          ptyext_path=name; ptyext_params=params; ptyext_constructors=constructors; _
        } ->
        let name = unwrap_loc name in
        let params = List.map ~f:(fun (ct, _) -> CoreType ct) params in
        let constructors = List.map ~f:(unwrap_extension_constructor) constructors in
        let bounds = Some (range, TypeExtension) in
        (* TODO: may need sorting *)
        Sequence (bounds, [], name, params @ constructors)
      (* type t1 += ... *)
      | Parsetree.Psig_class_type (_ :: _ as cdls) ->
        begin
          match List.map ~f:(unwrap_class_type_declaration) cdls with
          | [] -> assert false
          | h :: t ->
            let bounds = Some (range, ClassTypeDeclaration) in 
            Sequence (bounds, [], h, t)
        end

      | _ -> Signature_item si
    end
  | Structure_item ({ pstr_desc; _ } as si) -> begin match pstr_desc with
      | Parsetree.Pstr_eval (expr, attr) ->
        let current = Expression expr in
        let right = List.map ~f:(fun v -> Attribute v) attr in
        let bounds = Some (range, Eval) in
        Sequence (bounds, [], current, right)
      (* E *)
      | Parsetree.Pstr_value (_, v :: vb) ->
        let right = List.map ~f:(fun vb -> Value_binding vb) vb in
        let left = [] in
        let current = Value_binding v in
        let bounds = Some (range, LetBinding) in
        Sequence (bounds,left,current,right)
      (* let P1 = E1 and ... and Pn = EN *)
      | Parsetree.Pstr_primitive {
          pval_name=loc;
          pval_type; _
        } ->
        let name = unwrap_loc loc in 
        let ty = CoreType pval_type in
        let bounds = Some (range, ValueDeclaration) in
        Sequence (bounds, [], name, [ty])
      (* val x : int
         or 
         external x : int -> int = "x" *)
      | Parsetree.Pstr_type (_, t :: ts) ->
        let right = List.map ~f:(fun vb -> Type_declaration vb) ts in
        let left = [] in
        let current = Type_declaration t in
        let bounds = Some (range, TypeDefinition) in
        Sequence (bounds,left,current,right)
      (* type t1 = .. and t2 = .. *)
      | Parsetree.Pstr_module module_binding ->
        let mb = unwrap_module_binding module_binding in
        let bounds = Some (range, ModuleDefinition) in
        Sequence (bounds, [], mb, [])
      (* module M : M = struct ... end *)
      | Parsetree.Pstr_recmodule vs ->
        let vs = List.map ~f:unwrap_module_binding vs in
        let bounds = Some (range, ModuleDefinition) in
        begin
          match vs with
          | h :: t -> Sequence (bounds, [], h, t)
          | [] -> Structure_item si
        end
      (* module rec M1 = struct ... end and M2 = struct ... end *)
      | Parsetree.Pstr_modtype { pmtd_name=loc; pmtd_type; _ } ->
        let loc = unwrap_loc loc in 
        let ty = Option.bind ~f:unwrap_module_type pmtd_type
                 |> Option.to_list in
        let bounds = Some (range, ModuleTypeDefinition) in
        Sequence (bounds, [], loc, ty)
      (* module type M1  *)
      | Parsetree.Pstr_include { pincl_mod=expr;  _ }
      | Parsetree.Pstr_open { popen_expr=expr; _ } ->
        let expr = unwrap_module_expr expr |> Option.to_list in
        let items = expr in
        let bounds = Some (range, ModuleOpen) in
        begin
          match items with
          | h :: t -> Sequence (bounds, [], h, t)
          | [] -> Structure_item si
        end
      | Parsetree.Pstr_attribute attr -> Attribute attr
      | Parsetree.Pstr_typext { ptyext_path=name; ptyext_params=params;
                                ptyext_constructors=constructors; _ } ->
        let name = unwrap_loc name in
        let params = List.map ~f:(fun (ct, _) -> CoreType ct) params in
        let constructors = List.map ~f:(unwrap_extension_constructor) constructors in
        let bounds = Some (range, TypeExtension) in
        (* TODO: may need sorting *)
        Sequence (bounds, List.rev params, name,  constructors)
      (*  type t1 += C of int *)
      | Parsetree.Pstr_class (_ :: _ as cdl) ->
        let items = List.map ~f:unwrap_class_declaration cdl in 
        let bounds = Some (range, ClassDefinition) in
        begin
          match items with
          | [] -> assert false
          | h :: t  -> Sequence (bounds, [], h, t)
        end
      | Parsetree.Pstr_class_type (_ :: _ as cdl) -> 
        let items = List.map ~f:unwrap_class_type_declaration cdl  in 
        let bounds = Some (range, ClassTypeDefinition) in
        begin
          match items with
          | [] -> assert false
          | h :: t  -> Sequence (bounds, [], h, t)
        end
      | Parsetree.Pstr_exception exn -> unwrap_exception ~range exn
      | Parsetree.Pstr_extension (ext, _) ->
        let ext = unwrap_extensions ext in
        Sequence (Some (range, Extension), [], ext, [])
      | _ -> Structure_item si
    end
  | v ->
    v
and unwrap_class_type_declaration ({
    pci_params=params;
    pci_name;
    pci_expr; _
  }: Parsetree.class_type_declaration) =
  let name = unwrap_loc pci_name in
  let params = List.map ~f:(fun (ct,_) -> CoreType ct) params in
  let expr = unwrap_class_type pci_expr in
  let items = name :: params @ [expr] in
  let items = t_sort items in
  match items with
  | [] -> assert false
  | h::t ->
    let range =
      let sequence = Sequence (None, [], h, t) in
      t_to_bounds sequence
    in
    let bounds = Some (range, ClassTypeDefinition) in
    Sequence (bounds, [], h, t)
and unwrap_class_declaration ({
    pci_params=params; pci_name; pci_expr; _
  }: Parsetree.class_declaration) =
  let name = unwrap_loc pci_name in
  let params = List.map ~f:(fun (ct,_) -> CoreType ct) params in
  let expr = unwrap_class_expr pci_expr in
  let items = name :: params @ [expr] in
  let items = t_sort items in
  match items with
  | [] -> assert false
  | h::t ->
    let range =
      let sequence = Sequence (None, [], h, t) in
      t_to_bounds sequence
    in
    let bounds = Some (range, ClassDefinition) in
    Sequence (bounds, [], h, t)
and go_down (MkLocation (current,parent)) =
  match t_descend current with
  | Sequence (bounds, [],focused,[]) ->
    go_down (MkLocation (focused, Node {below=[];parent;above=[]; bounds;}))
  | Sequence (bounds, left,focused,right) ->
    Some (MkLocation (focused, Node {below=left;parent;above=right; bounds;}))
  | _ -> None

let make_zipper_intf left intf right =
  let left = List.map ~f:(fun x -> Signature_item x) left in
  let right = List.map ~f:(fun x -> Signature_item x) right in
  let intf = Signature_item intf in
  MkLocation (Sequence (None, List.rev left, intf, right), Top)

let make_zipper_impl left impl right =
  let left = List.map ~f:(fun x -> Structure_item x) left in
  let right = List.map ~f:(fun x -> Structure_item x) right in
  let impl = Structure_item impl in
  MkLocation (Sequence (None, List.rev left, impl, right), Top)

let at_start current point =
  match current with
  | Structure_item { pstr_loc = { loc_start; _ }; _ }
  | Signature_item { psig_loc = { loc_start; _ }; _ } ->
    loc_start.pos_cnum = point
  | _ -> false

(** moves the location to the nearest expression enclosing or around it   *)
let rec move_zipper_to_point point line forward loc =
  (* if not forward then Ecaml.message "moving backward"; *)
  let distance region =
    (* let region_line = Text_region.line_start region in 
     * let region_column = Text_region.column_start region in  *)
    match Text_region.distance_line ~forward region ~point ~line with
    | None,None -> Int.max_value, Int.max_value
    | None, Some line -> (Int.max_value, line)  
    | Some col, None -> (col, Int.max_value)  
    | Some col, Some line -> (col, line)  in
  match loc with
  | MkLocation (Sequence (bounds, l,c,r), parent) ->
    (* finds the closest strictly enclosing item *)
    let find_closest_enclosing ls =
      let rec loop ls acc =
        match ls with
        | h :: t ->
          if Text_region.contains_point (t_to_bounds h) point
          then Some (acc, h, t)
          else loop t (h :: acc)
        | [] -> None in
      loop ls [] in
    begin match find_closest_enclosing (List.rev l @ c :: r)  with
      (* we found an enclosing expression - go into it *)
      | Some (l,c,r) ->
        move_zipper_to_point point line forward
          (MkLocation (c, Node {below=l;parent; above=r; bounds;}))
      (* none of the subelements contain the point - find the closest one *)
      | None ->
        let sub_items = (List.rev l @ c :: r)
                        |> List.map ~f:(fun elem -> distance (t_to_bounds elem), elem) in
        let min_item = List.min_elt
            ~compare:(fun (d,_) (d',_) ->
                Tuple2.compare ~cmp1:Int.compare ~cmp2:Int.compare  d d'
              ) sub_items in
        match min_item with
        | None -> (* this can never happen - list always has at least 1 element *) assert false
        | Some (min, _) ->
          begin match List.split_while sub_items ~f:(fun (d,_) ->
              not @@ Tuple2.equal ~eq1:Int.equal ~eq2:Int.equal d min
            ) with
          | ([],(_, c) :: r) ->
            (* let start_col = Text_region.column_start (t_to_bounds c) in *)
            let sel_line = Text_region.line_start (t_to_bounds c) in
            let r = List.map ~f:snd r in
            if sel_line > line && (not forward)
            then (MkLocation (Sequence (bounds, [],c,r), parent))
            else
              move_zipper_to_point point line forward
                (MkLocation (c, Node {below=l; parent; above=r; bounds}))
          | (l,(_, c) :: r) ->
            let l = List.map ~f:snd l |> List.rev in
            let r = List.map ~f:snd r in
            move_zipper_to_point point line forward
              (MkLocation (c, Node {below=l; parent; above=r; bounds}))
          | _ -> assert false
          end
    end
  | (MkLocation (current,parent) as v) ->
    let current_bounds =  (t_to_bounds current) in 
    if Text_region.equals_point ~forward current_bounds point
    then begin
      v
    end
    else if Text_region.contains_point current_bounds point
    then begin
      match t_descend current with
      | (Sequence _ as s) ->
        let (MkLocation (current', _) as zipper) =
          move_zipper_to_point point line forward (MkLocation (s,parent)) in
        let selected_distance =
          distance (t_to_bounds current') in
        let enclosing_distance =
          distance (t_to_bounds current) in
        if (snd enclosing_distance < snd selected_distance) ||
           ((snd enclosing_distance = snd selected_distance) &&
            (fst enclosing_distance < fst selected_distance))
        then v
        else zipper
      | v -> (MkLocation (v, parent))
    end
    else v

(** determines whether the item is a toplevel thing that can be freely
    moved around - (internal let in etc. are not supported within the
    zipper.) *)
let is_top_level  = function
  | Structure_item _ 
  | Signature_item _
  | Sequence (None, _, _ , _) 
  | Sequence (Some (_, ValueBinding), _, _ , _) 
  | Sequence (Some (_, ModuleDeclaration), _, _ , _) 
  | Sequence (Some (_, ModuleDefinition), _, _ , _) -> true
  | _ -> false

(** determines whether the parent is a top-level item - i.e supports
    inserting and removing other top level items freely *)
let is_top_level_parent (z:zipper)  =
  match z with
  | Node { bounds=None; _ }
  | Top -> true
  | Node { bounds=Some(_,v); _ } ->
    match v with
    | ModuleSignature
    | ModuleStructure -> true
    | _ -> false

(** determines whether the current is a pattern *)
let is_pattern  = function
  | EmptySequence (_, Pattern)
  | Sequence (Some (_, Pattern), _, _, _)
  | Pattern _ -> true
  | _ -> false

let is_pattern_or_expression  = function
  | Expression _
  | EmptySequence (_, Pattern)
  | Sequence (Some (_, Pattern), _, _, _)
  | Pattern _ -> true
  | _ -> false


let describe_current_item  (MkLocation (current,_)) =
  (to_string current)

let describe_zipper = function
  | Top -> "Top"
  | Node { bounds; _ } -> match bounds with
    | None -> "TopSequence"
    | Some (_,ty) -> "Sequence of " ^ (show_unwrapped_type ty)

let zipper_is_top_level (MkLocation (current,_))  =
  is_top_level current

let zipper_is_top_level_parent (MkLocation (_,parent))  =
  is_top_level_parent parent

let zipper_is_pattern (MkLocation (current,_))  =
  is_pattern current

let zipper_is_first (MkLocation (_, parent)) =
  match parent with
  | Top -> true
  | Node {  below=b; _ } ->
    match b with
    | [] -> true
    | _ -> false


(** moves the location to the nearest structure item enclosing or around it   *)
let rec move_zipper_broadly_to_point point line forward loc =
  let distance region =
    match Text_region.distance ~forward region point with
    | None -> Int.max_value
    | Some col -> col in
  let contains =
    let MkLocation (current,_) = loc in 
    let contains = Text_region.contains_ne_point (t_to_bounds current) point in 
    contains
  in

  if contains then
    match loc with
    | MkLocation (Sequence (bounds, l,c,r), parent) ->
      (* finds the closest strictly enclosing item *)
      let  find_closest_enclosing ls =
        let rec loop ls acc =
          match ls with
          | h :: t ->
            if Text_region.contains_point (t_to_bounds h) point
            then Some (acc, h, t)
            else loop t (h :: acc)
          | [] -> None in
        loop ls [] in
      begin
        match find_closest_enclosing (List.rev l @ c :: r)  with
        (* we found an enclosing expression - go into it *)
        | Some (l,c,r) ->
          move_zipper_broadly_to_point point line forward
            (MkLocation (c, Node {below=l;parent; above=r; bounds;}))
        (* none of the subelements contain the point - find the closest one *)
        | None ->
          let sub_items = (List.rev l @ c :: r)
                          |> List.map ~f:(fun elem -> distance (t_to_bounds elem), elem) in
          let min_item = List.min_elt
              ~compare:(fun (d,_) (d',_) ->
                  Int.compare d d'
                ) sub_items in
          match min_item with
          | None -> (* this can never happen - list always has at least 1 element *) assert false
          | Some (min_v,_) ->
            begin match List.split_while sub_items ~f:(fun (d,_) ->
                not @@ Int.(d =  min_v)
              ) with
            | ([],(_, c) :: r) ->
              let c_bounds = t_to_bounds c in 
              let r = List.map ~f:snd r in
              if not forward && Text_region.before_point c_bounds point then
                (MkLocation (Sequence (bounds, [],c,r), parent))
              else   
                move_zipper_broadly_to_point point line forward
                  (MkLocation (c, Node {below=l; parent; above=r; bounds}))
            | (l,(_, c) :: r) ->
              let l = List.map ~f:snd l |> List.rev in
              let r = List.map ~f:snd r in
              move_zipper_broadly_to_point point line forward
                (MkLocation (c, Node {below=l; parent; above=r; bounds}))
            | _ -> assert false
            end
      end
    | (MkLocation (current,parent) as v) ->
      if Text_region.contains_ne_point (t_to_bounds current) point
      then
        begin
          let descend = t_descend current in
          if not (is_top_level descend)
          then
            begin
              v
            end
          else
            match descend with
            | (Sequence _ as s) ->
              let (MkLocation (_current', _) as zipper) =
                move_zipper_broadly_to_point point line forward (MkLocation (s,parent)) in
              let descend_region =
                (t_to_bounds _current') in
              if (not forward && (zipper_is_first zipper) &&
                  (Text_region.before_point descend_region point))
              then begin
                v
              end
              else zipper
            | v -> (MkLocation (v, parent))

        end
      else v
  else loc

let insert_element (MkLocation (current,parent)) (element: t)  =
  let (>>=) x f = Option.bind ~f x in
  match parent with
  | Top -> None
  | Node {below; parent; above; bounds} ->
    (* range of the current item *)
    let current_range = t_to_bounds current in
    let insert_range = t_to_bounds element in
    let editing_pos = snd (Text_region.to_bounds current_range) in
    (* position of the start of the empty structure *)
      (Text_region.diff_between current_range insert_range 
      |> Option.map ~f:(Text_region.Diff.add_newline_with_indent ~indent:0)
      |> Option.map ~f:(Text_region.Diff.add_newline_with_indent ~indent:0)) >>= fun shift_backwards ->

    let element =
      (* update the structure to be positioned at the right location *)
      t_shift_by_offset ~diff:shift_backwards element in
    (* calculate the diff after inserting the item *)
    (insert_range
      |> Text_region.to_diff
      (* we're inserting rather than deleting *)
      |> Option.map ~f:Text_region.Diff.negate 
      (* newline after end of current element *)
      |> Option.map ~f:(Text_region.Diff.add_newline_with_indent ~indent:0) 
      (* 1 more newline and then offset *)
      |> Option.map ~f:(Text_region.Diff.add_newline_with_indent ~indent:0) 
      (* newline after end of inserted element *)
      |> Option.map ~f:(Text_region.Diff.add_newline_with_indent ~indent:0)) >>= fun diff -> 
    let update_bounds = update_bounds ~diff in
    let update_meta_bound bounds = 
      match bounds with
        None -> None
      | Some (bounds,ty) -> Some (Text_region.extend_region bounds diff,ty)
    in
    (* update parent *)
    let rec update_parent parent = match parent with
      | Top -> Top
      | Node {below;parent;above; bounds} ->
        let above = List.map ~f:update_bounds above in
        let bounds = update_meta_bound bounds in
        let parent = update_parent parent in 
        Node {below; parent; above; bounds} in
    let parent = update_parent parent in
    let above = List.map ~f:update_bounds above in
    let bounds = update_meta_bound bounds in
    let parent = Node {below=current::below; parent; above; bounds} in
    Some (MkLocation (element,parent), editing_pos)

let go_up (MkLocation (current,parent)) =
  match parent with
  | Top -> None
  | Node { below; parent; above; bounds } ->
    let current = Sequence (bounds, below,current,above) in
    Some (MkLocation (current,parent))

let rec go_left ?left_bounds (MkLocation (current,parent) as loc) =
  let calculate_bounds (MkLocation (current, _)) = t_to_bounds current |> Text_region.column_start in 
  let left_bounds = match left_bounds with
    | Some v -> v
    | None -> calculate_bounds loc in 
  match parent with
  | Node { bounds; below=l::left; parent; above } ->
    Some (MkLocation (l, Node {below=left; parent; above=current::above; bounds}))
  | _ ->
    match go_up loc with
    | None -> None
    | Some zipper ->
      let new_left_bounds = calculate_bounds zipper in
      if new_left_bounds = left_bounds then
        Some (Option.value (go_left ~left_bounds zipper) ~default:zipper)
      else Some zipper

let rec go_right ?right_bounds (MkLocation (current,parent) as loc) =
  let calculate_bounds (MkLocation (current, _)) = t_to_bounds current |> Text_region.column_end in 
  let right_bounds = match right_bounds with
    | Some v -> v
    | None -> calculate_bounds loc in 
  match parent with
  | Node { below; parent; above=r::right; bounds } ->
    Some (MkLocation (r, Node {below=current::below; parent; above=right; bounds}))
  | _ -> 
    match go_up loc with
    | None -> None
    | Some zipper ->
      let new_right_bounds = calculate_bounds zipper in
      if new_right_bounds = right_bounds then
        Some (Option.value (go_right ~right_bounds zipper) ~default:zipper)
      else Some zipper

(** deletes the current element of the zipper  *)
let calculate_zipper_delete_bounds (MkLocation (current,_) as loc) =
  let (>>=) x f = Option.bind ~f x in
  let current_bounds =  t_to_bounds current in
  (Text_region.to_diff current_bounds) >>= fun diff -> 
  let update_bounds = update_bounds ~diff in
  let update_meta_bound bounds = 
    match bounds with None -> None | Some (bounds,ty) -> Some (Text_region.extend_region bounds diff,ty)
  in
  (* update parent *)
  let rec update_parent parent = match parent with
    | Top -> Top
    | Node {below;parent;above; bounds} ->
      let above = List.map ~f:update_bounds above in
      let bounds = update_meta_bound bounds in
      let parent = update_parent parent in 
      Node {below; parent; above; bounds} in
  (* returns a zipper with the first element removed *)
  let rec remove_current  (MkLocation (current,parent)) = 
    match parent with
    | Top -> None
    | Node {below; parent=up; above=r::right; bounds} ->
      let r = update_bounds r in
      let right = List.map ~f:update_bounds right in
      let up = update_parent up in
      let bounds = update_meta_bound bounds in
      Some (MkLocation(r, Node{below;parent=up;above=right; bounds}))
    | Node {below=l::left; parent=up; above=right; bounds} ->
      let right = List.map ~f:update_bounds right in
      let up = update_parent up in
      let bounds = update_meta_bound bounds in
      Some (MkLocation(l, Node{below=left;parent=up;above=right; bounds}))
    | Node {below=[]; parent=up; above=[]; bounds=(Some (bounds, ty)) } ->
      let up = update_parent up in
      Some (MkLocation (EmptySequence (Text_region.extend_region bounds diff,ty), up)) 
    | Node {below=[]; parent=up; above=[]; _} ->
      remove_current (MkLocation (current, up)) in
  remove_current loc |> Option.map ~f:(fun v -> v,current_bounds)

let update_zipper_space_bounds (MkLocation (current,parent))
    (pre_column,pre_line) (post_column,post_line) =
  if not (is_top_level_parent parent) || not (is_top_level current) then begin
    None
  end
  else 
    let pre_diff = Text_region.Diff.of_pair ~line:pre_line ~col:pre_column
                   |> Text_region.Diff.negate in
    let post_diff = Text_region.Diff.of_pair ~line:post_line ~col:post_column
                    |> Text_region.Diff.negate in
    let current = t_shift_by_offset ~diff:pre_diff current in
    let diff = Text_region.Diff.combine pre_diff post_diff in
    let update_bounds = update_bounds ~diff in
    let update_meta_bound bounds = 
      match bounds with None -> None
                      | Some (bounds,ty) -> Some (Text_region.extend_region bounds diff,ty)
    in
    (* update parent *)
    let rec update_parent parent = match parent with
      | Top -> Top
      | Node {below;parent;above; bounds} ->
        let above = List.map ~f:update_bounds above in
        let bounds = update_meta_bound bounds in
        let parent = update_parent parent in 
        Node {below; parent; above; bounds} in
    match parent with
    | Top -> None
    | Node {below; parent=up; above=right; bounds} ->
      let right = List.map ~f:update_bounds right in
      let parent = update_parent up in
      let bounds = update_meta_bound bounds in
      Some (MkLocation(current, Node{below;parent;above=right; bounds}))

let move_up (MkLocation (current,_) as loc)  =
  let rec loop loc =
    match loc with
    | None -> None
    | Some (MkLocation
              (_, parent) as loc) ->
      if not (is_top_level_parent parent) then
        loop (go_up loc)
      else Some (loc) in 
  let (>>=) x f = Option.bind ~f x in
  (loop (Some loc)) >>= fun loc -> 
  (calculate_zipper_delete_bounds loc) >>= fun (loc,bounds) ->
  (*  first we go up once - this is the enclosing structure:
      module S = struct _ ... _ end
      ->
      module S = _ struct  ...  end _
  *)
  (go_up loc) >>= fun loc ->
  (loop (Some loc)) >>= fun loc -> 
  (insert_element loc current) >>= fun (loc,insert_pos) ->
  Some (loc, insert_pos, Text_region.to_bounds bounds)

let go_start loc =
  match loc with
  | (MkLocation (current, (Node {bounds; below;parent;above})) as loc) -> 
    begin
      match split_last below with
      | None -> loc
      | Some (belast,last) ->
        (
          MkLocation (
            last,
            Node {
              bounds;
              parent;
              above=(List.rev belast) @ current::above;
              below=[];
            }
          )
        )
    end
  | _ -> loc

let move_down (MkLocation (current,_) as loc)  =
  let rec loop loc =
    match loc with
    | None -> None
    | Some (MkLocation
              (_, parent) as loc) ->
      if not (is_top_level_parent parent) then
        loop (go_up loc)
      else Some (loc) in
  let rec loop_forward loc =
    match loc with
    | None -> None
    | Some (MkLocation (_, parent) as loc) ->
      if not (is_top_level_parent parent) then
        match go_down loc |> Option.map ~f:go_start with
        | None -> loop_forward (go_right loc)
        | v -> loop_forward v
      else Some loc
  in 
  begin
    let (>>=) x f = Option.bind ~f x in
    (loop (Some loc)) >>= fun loc -> 
    (calculate_zipper_delete_bounds loc) >>= fun (loc,bounds) -> 
    (go_down loc |> Option.map ~f:go_start) >>= fun (MkLocation (_,_) as loc) -> 
    (loop_forward (Some loc)) >>= fun loc -> 
    (insert_element loc current) >>= fun (loc,insert_pos) -> 
    Some (loc, insert_pos, Text_region.to_bounds bounds)
  end

(** swaps two elements at the same level, returning the new location  *)
let calculate_swap_bounds (MkLocation (current,parent)) =
  match parent with
  | Node { below=l::left; parent; above=r::right; bounds } ->
    let (>>=) x f = Option.bind ~f x in
    let current_bounds =  t_to_bounds current in
    let prev_bounds = t_to_bounds l in
    (Text_region.swap_diff current_bounds prev_bounds) >>= fun (prev_diff,current_diff) -> 
    Some (
      current_bounds,
      prev_bounds,
      (MkLocation (
          r,
          (Node {
              below=(update_bounds ~diff:prev_diff l)::(update_bounds ~diff:current_diff current)::left;
              parent;
              above=right;
              bounds
            }))))
  | _ -> None

(** swaps two elements forward at the same level, returning the new location  *)
let calculate_swap_forward_bounds (MkLocation (current,parent)) =
  match parent with
  | Node { below=left; parent; above=r::right; bounds } ->
    let (>>=) x f = Option.bind ~f x in
    let current_bounds =  t_to_bounds current in
    let prev_bounds = t_to_bounds r in
    (Text_region.swap_diff prev_bounds current_bounds) >>= fun (current_diff,prev_diff) -> 
    Some (
      current_bounds,
      prev_bounds,
      MkLocation (
        (update_bounds ~diff:current_diff current),
        (Node {
            below=(update_bounds ~diff:prev_diff r)::left;
            parent;
            above=right; bounds
          })))
  | _ -> None

(** swaps two elements forward at the same level, returning the new location  *)
let calculate_swap_backwards_bounds (MkLocation (current,parent)) =
  match parent with
  | Node { below=l::left; parent; above=right; bounds } ->
    let (>>=) x f = Option.bind ~f x in
    let current_bounds =  t_to_bounds current in
    let prev_bounds = t_to_bounds l in
    (Text_region.swap_diff current_bounds prev_bounds) >>= fun (prev_diff,current_diff) ->
    Some (
      current_bounds,
      prev_bounds,
      MkLocation (
        (update_bounds ~diff:current_diff current),
        (Node {
            below=left;
            parent;
            above=(update_bounds ~diff:prev_diff l)::right;
            bounds
          })))
  | _ -> None

(** finds the item bounds for the nearest structure/signature (essentially defun) item  *)
let find_nearest_definition_item_bounds point line forward zipper : _ option =
  let zipper = move_zipper_broadly_to_point point line forward zipper in
  let rec loop zipper =
    let get_result pos_start pos_end =
      if (not forward && point = pos_start)
      then
        begin
          (go_left zipper) |> Option.bind ~f:loop
        end
      else if (forward && (point - 1) = pos_end)
      then
        begin
          (go_right zipper) |> Option.bind ~f:loop
        end
      else if forward then begin
        Some pos_end
      end
      else Some pos_start in
    let MkLocation (current,_) = zipper in
    match current with
    | Signature_item { psig_loc = { loc_start; loc_end; _ }; _ } 
    | Structure_item {  pstr_loc = { loc_start; loc_end; _ };_ } ->
      get_result loc_start.pos_cnum loc_end.pos_cnum
    | Sequence (Some (bound,_), _,_,_) ->
      let start_column = Text_region.column_start bound in
      let end_column = Text_region.column_end bound in
      get_result start_column end_column
    | Sequence (None, _,_,_) ->
      let bound = (t_to_bounds current) in
      let start_column = (Text_region.column_start bound) in
      let end_column = Text_region.column_end bound in
      get_result start_column end_column
    | _ ->
      (go_up zipper) |> Option.bind ~f:loop
  in
  loop zipper


let go_end loc =
  match loc with
  | (MkLocation (current, (Node {bounds; below;parent;above})) as loc) -> 
    begin
      match split_last above with
      | None -> loc
      | Some (belast,last) ->
        (
          MkLocation (
            last,
            Node {
              bounds;
              parent;
              below=(List.rev belast) @ current::below;
              above=[];
            }
          )
        )
    end
  | _ -> loc



(** move across the tree in an enumerative way - i.e
    move left, once at start, move up and move to end of upper section  *)
let go_left_enumerative (MkLocation (current,parent) as loc) =
  match parent with
  | Node { bounds; below=l::left; parent; above } ->
    Some (MkLocation (l, Node {below=left; parent; above=current::above; bounds}))
  | _ ->
    match go_up loc with
    | None -> None
    | Some (MkLocation (_, Top) as loc) -> Some loc
    | Some loc -> Some (go_end loc)

(** finds the nearest enclosing let def  *)
let rec goto_nearest_letdef point (MkLocation (current,parent) as loc)  =
  let is_vb parent = match parent with
    | Node {bounds=Some (_,v); _} ->
      begin
        match v with
        | ValueBinding -> true
        | _ -> false
      end
    | _ -> false
  in
  let is_let_type v = begin
    match v with
    | Seq
    | LetModuleBinding
    | LetException
    | LetBinding
    | LetOp -> true
    | _ -> false
  end in 
  (* is the parent a letdef *)
  let is_letdef_parent parent = match parent with
    | Node {bounds=Some (_,v); _} -> is_let_type v
    | _ -> false in
  (* is the current element a valuebinding *)
  let is_vb_child current =
    match current with
    | Sequence (Some (_, ValueBinding), _, _, _) 
    | Value_binding _ -> true
    | _ -> false
  in
  (* is parent a value binding *)
  let is_vb_parent parent =
    match  parent with
    | Node {bounds=Some(_,v); _ } ->
      begin
        match v with
        | ValueBinding -> true
        | _ -> false
      end
    | _ -> false
  in
  if is_vb parent && is_pattern current then
    begin
      let bounds = t_to_bounds current |> Text_region.column_start in
      (* if the point is at the start of a pattern, then continue search up *)
      if not Int.(bounds = point) then
        let result = begin
          let items = match parent with
            | Node {below=_::_ as l; _} -> current :: l
            | _ -> [current]
          in
          let items = List.take_while ~f:is_pattern_or_expression items in
          List.last items
        end in
        match result with
        | Some _ -> result
        | None -> go_left loc |> Option.bind ~f:(goto_nearest_letdef point)
      else
        begin
          if is_vb_parent parent then
            go_up loc |> Option.bind ~f:(go_left) |> Option.bind ~f:(goto_nearest_letdef point)
          else
            go_left loc |> Option.bind ~f:(goto_nearest_letdef point)
        end
    end
  else if is_letdef_parent parent && is_vb_child current then
    begin
      go_down loc |> Option.bind ~f:(goto_nearest_letdef point)
    end
  else
    begin
      go_left loc |> Option.bind ~f:(goto_nearest_letdef point)
    end

(** finds the nearest enclosing let def  *)
let find_nearest_letdef point loc  =
  goto_nearest_letdef point loc
  |> Option.map ~f:(fun v -> t_to_bounds v |> Text_region.column_start )

(** finds the nearest enclosing let def  *)
let find_nearest_letdef_end point loc  =
  goto_nearest_letdef point loc
  |> Option.map ~f:(fun v -> t_to_bounds v |> Text_region.column_end )

(** finds a wildcard if any exists within a term  *)
let rec find_wildcard (t: t) : t option  =
  (match t_descend t with
   | Wildcard _ as t -> Some t
   | Sequence (Some (_, Pattern), before, current, rest) ->
     List.find_map ~f:find_wildcard ((List.rev before) @ current :: rest)
   | _ -> None)

(** finds a pattern variable if any exists within a term *)
let rec find_pattern_variable (t: t) : t option  =
  (match t_descend t with
   | Pattern ({ppat_desc=Parsetree.Ppat_var _; _}) -> Some t
   | Wildcard _ as t -> Some t
   | Sequence (Some (_, Pattern), before, current, rest) ->
     List.find_map ~f:find_pattern_variable ((List.rev before) @ current :: rest)
   | _ -> None)


(** finds the nearest enclosing wildcard  *)
let rec find_nearest_pattern point (MkLocation (current,parent) as loc)  =
  if is_pattern current then
    begin
      let bounds = t_to_bounds current |> Text_region.column_start in
      (* if the point is at the start of a pattern, then continue suearch up *)
      if Int.(bounds = point) then
        go_left loc |> Option.bind ~f:(find_nearest_pattern point)
      else
        let result = begin
          (* retrieve all elements before element at current level *)
          let items = match parent with
            | Node {below=_::_ as l; _} -> current :: l | _ -> [current] in
          let is_value_binding = match parent with
            | Node {bounds=Some (_,ValueBinding); _}  -> true
            | _ -> false in 
          let items = List.take_while ~f:is_pattern items in
          (* let items = List.rev items in *)
          (* if in valuebinding, then first pattern is name of operation *)
          let items = if is_value_binding then List.drop_last items |> Option.value ~default:[] else items in 
          (* let items = List.rev items in *)
          (* now, have list of patterns
             - try find wildcard fist
             - no wildcard, find pattern first,
             - no pattern return last
          *)
          let result =
            let (>>=) x f = match x with Some v -> Some v | None -> f () in
            (List.find_map ~f:find_wildcard items) >>= fun () -> 
            (List.find_map ~f:find_pattern_variable items) >>= fun () -> 
            List.last items in
          Option.map ~f:(fun v -> t_to_bounds v |> Text_region.column_start) result
        end in
        match result with
        | Some _ -> result
        | None -> go_left loc |> Option.bind ~f:(find_nearest_pattern point)
    end
  else go_left loc |> Option.bind ~f:(find_nearest_pattern point)

(* (\** finds scopes enclosing item  *\)
 * let find_enclosing_scopes = (??) *)
