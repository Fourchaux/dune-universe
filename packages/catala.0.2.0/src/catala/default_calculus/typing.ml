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

(** Typing for the default calculus. Because of the error terms, we perform type inference using the
    classical W algorithm with union-find unification. *)

module Pos = Utils.Pos
module Errors = Utils.Errors
module A = Ast
module Cli = Utils.Cli

(** {1 Types and unification} *)

(** We do not reuse {!type: Dcalc.Ast.typ} because we have to include a new [TAny] variant. Indeed,
    error terms can have any type and this has to be captured by the type sytem. *)
type typ =
  | TLit of A.typ_lit
  | TArrow of typ Pos.marked UnionFind.elem * typ Pos.marked UnionFind.elem
  | TTuple of typ Pos.marked UnionFind.elem list
  | TEnum of typ Pos.marked UnionFind.elem list
  | TAny

let rec format_typ (fmt : Format.formatter) (ty : typ Pos.marked UnionFind.elem) : unit =
  let ty_repr = UnionFind.get (UnionFind.find ty) in
  match Pos.unmark ty_repr with
  | TLit l -> Format.fprintf fmt "%a" Print.format_tlit l
  | TAny -> Format.fprintf fmt "any type"
  | TTuple ts ->
      Format.fprintf fmt "(%a)"
        (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.fprintf fmt " * ") format_typ)
        ts
  | TEnum ts ->
      Format.fprintf fmt "(%a)"
        (Format.pp_print_list ~pp_sep:(fun fmt () -> Format.fprintf fmt " + ") format_typ)
        ts
  | TArrow (t1, t2) -> Format.fprintf fmt "%a → %a" format_typ t1 format_typ t2

(** Raises an error if unification cannot be performed *)
let rec unify (t1 : typ Pos.marked UnionFind.elem) (t2 : typ Pos.marked UnionFind.elem) : unit =
  (* Cli.debug_print (Format.asprintf "Unifying %a and %a" format_typ t1 format_typ t2); *)
  let t1_repr = UnionFind.get (UnionFind.find t1) in
  let t2_repr = UnionFind.get (UnionFind.find t2) in
  match (t1_repr, t2_repr) with
  | (TLit tl1, _), (TLit tl2, _) when tl1 = tl2 -> ()
  | (TArrow (t11, t12), t1_pos), (TArrow (t21, t22), t2_pos) -> (
      try
        unify t11 t21;
        unify t12 t22
      with Errors.StructuredError (msg, err_pos) ->
        Errors.raise_multispanned_error msg
          ( err_pos
          @ [
              (Some (Format.asprintf "Type %a coming from expression:" format_typ t1), t1_pos);
              (Some (Format.asprintf "Type %a coming from expression:" format_typ t2), t2_pos);
            ] ) )
  | (TTuple ts1, _), (TTuple ts2, _) -> List.iter2 unify ts1 ts2
  | (TEnum ts1, _), (TEnum ts2, _) -> List.iter2 unify ts1 ts2
  | (TAny, _), (TAny, _) -> ignore (UnionFind.union t1 t2)
  | (TAny, _), t_repr | t_repr, (TAny, _) ->
      let t_union = UnionFind.union t1 t2 in
      ignore (UnionFind.set t_union t_repr)
  | (_, t1_pos), (_, t2_pos) ->
      (* TODO: if we get weird error messages, then it means that we should use the persistent
         version of the union-find data structure. *)
      Errors.raise_multispanned_error
        (Format.asprintf "Error during typechecking, types %a and %a are incompatible" format_typ t1
           format_typ t2)
        [
          (Some (Format.asprintf "Type %a coming from expression:" format_typ t1), t1_pos);
          (Some (Format.asprintf "Type %a coming from expression:" format_typ t2), t2_pos);
        ]

(** Operators have a single type, instead of being polymorphic with constraints. This allows us to
    have a simpler type system, while we argue the syntactic burden of operator annotations helps
    the programmer visualize the type flow in the code. *)
let op_type (op : A.operator Pos.marked) : typ Pos.marked UnionFind.elem =
  let pos = Pos.get_position op in
  let bt = UnionFind.make (TLit TBool, pos) in
  let it = UnionFind.make (TLit TInt, pos) in
  let rt = UnionFind.make (TLit TRat, pos) in
  let mt = UnionFind.make (TLit TMoney, pos) in
  let dut = UnionFind.make (TLit TDuration, pos) in
  let dat = UnionFind.make (TLit TDate, pos) in
  let any = UnionFind.make (TAny, pos) in
  let arr x y = UnionFind.make (TArrow (x, y), pos) in
  match Pos.unmark op with
  | A.Binop (A.And | A.Or) -> arr bt (arr bt bt)
  | A.Binop (A.Add KInt | A.Sub KInt | A.Mult KInt | A.Div KInt) -> arr it (arr it it)
  | A.Binop (A.Add KRat | A.Sub KRat | A.Mult KRat | A.Div KRat) -> arr rt (arr rt rt)
  | A.Binop (A.Add KMoney | A.Sub KMoney) -> arr mt (arr mt mt)
  | A.Binop (A.Add KDuration | A.Sub KDuration) -> arr dut (arr dut dut)
  | A.Binop (A.Sub KDate) -> arr dat (arr dat dut)
  | A.Binop (A.Add KDate) -> arr dat (arr dut dat)
  | A.Binop (A.Div KMoney) -> arr mt (arr mt rt)
  | A.Binop (A.Mult KMoney) -> arr mt (arr rt mt)
  | A.Binop (A.Lt KInt | A.Lte KInt | A.Gt KInt | A.Gte KInt) -> arr it (arr it bt)
  | A.Binop (A.Lt KRat | A.Lte KRat | A.Gt KRat | A.Gte KRat) -> arr rt (arr rt bt)
  | A.Binop (A.Lt KMoney | A.Lte KMoney | A.Gt KMoney | A.Gte KMoney) -> arr mt (arr mt bt)
  | A.Binop (A.Lt KDate | A.Lte KDate | A.Gt KDate | A.Gte KDate) -> arr dat (arr dat bt)
  | A.Binop (A.Lt KDuration | A.Lte KDuration | A.Gt KDuration | A.Gte KDuration) ->
      arr dut (arr dut bt)
  | A.Binop (A.Eq | A.Neq) -> arr any (arr any bt)
  | A.Unop (A.Minus KInt) -> arr it it
  | A.Unop (A.Minus KRat) -> arr rt rt
  | A.Unop (A.Minus KMoney) -> arr mt mt
  | A.Unop (A.Minus KDuration) -> arr dut dut
  | A.Unop A.Not -> arr bt bt
  | A.Unop A.ErrorOnEmpty -> arr any any
  | A.Unop (A.Log _) -> arr any any
  | Binop (Mult (KDate | KDuration)) | Binop (Div (KDate | KDuration)) | Unop (Minus KDate) ->
      Errors.raise_spanned_error "This operator is not available!" pos

let rec ast_to_typ (ty : A.typ) : typ =
  match ty with
  | A.TLit l -> TLit l
  | A.TArrow (t1, t2) ->
      TArrow
        ( UnionFind.make (Pos.map_under_mark ast_to_typ t1),
          UnionFind.make (Pos.map_under_mark ast_to_typ t2) )
  | A.TTuple ts -> TTuple (List.map (fun t -> UnionFind.make (Pos.map_under_mark ast_to_typ t)) ts)
  | A.TEnum ts -> TEnum (List.map (fun t -> UnionFind.make (Pos.map_under_mark ast_to_typ t)) ts)

let rec typ_to_ast (ty : typ Pos.marked UnionFind.elem) : A.typ Pos.marked =
  Pos.map_under_mark
    (fun ty ->
      match ty with
      | TLit l -> A.TLit l
      | TTuple ts -> A.TTuple (List.map typ_to_ast ts)
      | TEnum ts -> A.TEnum (List.map typ_to_ast ts)
      | TArrow (t1, t2) -> A.TArrow (typ_to_ast t1, typ_to_ast t2)
      | TAny -> A.TLit A.TUnit)
    (UnionFind.get (UnionFind.find ty))

(** {1 Double-directed typing} *)

type env = typ Pos.marked A.VarMap.t

(** Infers the most permissive type from an expression *)
let rec typecheck_expr_bottom_up (env : env) (e : A.expr Pos.marked) : typ Pos.marked UnionFind.elem
    =
  match Pos.unmark e with
  | EVar v -> (
      match A.VarMap.find_opt (Pos.unmark v) env with
      | Some t -> UnionFind.make t
      | None ->
          Errors.raise_spanned_error "Variable not found in the current context"
            (Pos.get_position e) )
  | ELit (LBool _) -> UnionFind.make (Pos.same_pos_as (TLit TBool) e)
  | ELit (LInt _) -> UnionFind.make (Pos.same_pos_as (TLit TInt) e)
  | ELit (LRat _) -> UnionFind.make (Pos.same_pos_as (TLit TRat) e)
  | ELit (LMoney _) -> UnionFind.make (Pos.same_pos_as (TLit TMoney) e)
  | ELit (LDate _) -> UnionFind.make (Pos.same_pos_as (TLit TDate) e)
  | ELit (LDuration _) -> UnionFind.make (Pos.same_pos_as (TLit TDuration) e)
  | ELit LUnit -> UnionFind.make (Pos.same_pos_as (TLit TUnit) e)
  | ELit LEmptyError -> UnionFind.make (Pos.same_pos_as TAny e)
  | ETuple es ->
      let ts = List.map (fun (e, _) -> typecheck_expr_bottom_up env e) es in
      UnionFind.make (Pos.same_pos_as (TTuple ts) e)
  | ETupleAccess (e1, n, _) -> (
      let t1 = typecheck_expr_bottom_up env e1 in
      match Pos.unmark (UnionFind.get (UnionFind.find t1)) with
      | TTuple ts -> (
          match List.nth_opt ts n with
          | Some t' -> t'
          | None ->
              Errors.raise_spanned_error
                (Format.asprintf
                   "Expression should have a tuple type with at least %d elements but only has %d" n
                   (List.length ts))
                (Pos.get_position e1) )
      | _ ->
          Errors.raise_spanned_error
            (Format.asprintf "Expected a tuple, got a %a" format_typ t1)
            (Pos.get_position e1) )
  | EInj (e1, n, _, ts) ->
      let ts = List.map (fun t -> UnionFind.make (Pos.map_under_mark ast_to_typ t)) ts in
      let ts_n =
        match List.nth_opt ts n with
        | Some ts_n -> ts_n
        | None ->
            Errors.raise_spanned_error
              (Format.asprintf
                 "Expression should have a sum type with at least %d cases but only has %d" n
                 (List.length ts))
              (Pos.get_position e)
      in
      typecheck_expr_top_down env e1 ts_n;
      UnionFind.make (Pos.same_pos_as (TEnum ts) e)
  | EMatch (e1, es) ->
      let enum_cases = List.map (fun (e', _) -> UnionFind.make (Pos.same_pos_as TAny e')) es in
      let t_e1 = UnionFind.make (Pos.same_pos_as (TEnum enum_cases) e1) in
      typecheck_expr_top_down env e1 t_e1;
      let t_ret = UnionFind.make (Pos.same_pos_as TAny e) in
      List.iteri
        (fun i (es', _) ->
          let enum_t = List.nth enum_cases i in
          let t_es' = UnionFind.make (Pos.same_pos_as (TArrow (enum_t, t_ret)) es') in
          typecheck_expr_top_down env es' t_es')
        es;
      t_ret
  | EAbs (pos_binder, binder, taus) ->
      let xs, body = Bindlib.unmbind binder in
      if Array.length xs = List.length taus then
        let xstaus = List.map2 (fun x tau -> (x, tau)) (Array.to_list xs) taus in
        let env =
          List.fold_left
            (fun env (x, tau) ->
              A.VarMap.add x (ast_to_typ (Pos.unmark tau), Pos.get_position tau) env)
            env xstaus
        in
        List.fold_right
          (fun t_arg (acc : typ Pos.marked UnionFind.elem) ->
            UnionFind.make
              (TArrow (UnionFind.make (Pos.map_under_mark ast_to_typ t_arg), acc), pos_binder))
          taus
          (typecheck_expr_bottom_up env body)
      else
        Errors.raise_spanned_error
          (Format.asprintf "function has %d variables but was supplied %d types" (Array.length xs)
             (List.length taus))
          pos_binder
  | EApp (e1, args) ->
      let t_args = List.map (typecheck_expr_bottom_up env) args in
      let t_ret = UnionFind.make (Pos.same_pos_as TAny e) in
      let t_app =
        List.fold_right
          (fun t_arg acc -> UnionFind.make (Pos.same_pos_as (TArrow (t_arg, acc)) e))
          t_args t_ret
      in
      typecheck_expr_top_down env e1 t_app;
      t_ret
  | EOp op -> op_type (Pos.same_pos_as op e)
  | EDefault (excepts, just, cons) ->
      typecheck_expr_top_down env just (UnionFind.make (Pos.same_pos_as (TLit TBool) just));
      let tcons = typecheck_expr_bottom_up env cons in
      List.iter (fun except -> typecheck_expr_top_down env except tcons) excepts;
      tcons
  | EIfThenElse (cond, et, ef) ->
      typecheck_expr_top_down env cond (UnionFind.make (Pos.same_pos_as (TLit TBool) cond));
      let tt = typecheck_expr_bottom_up env et in
      typecheck_expr_top_down env ef tt;
      tt
  | EAssert e' ->
      typecheck_expr_top_down env e' (UnionFind.make (Pos.same_pos_as (TLit TBool) e'));
      UnionFind.make (Pos.same_pos_as (TLit TUnit) e')

(** Checks whether the expression can be typed with the provided type *)
and typecheck_expr_top_down (env : env) (e : A.expr Pos.marked)
    (tau : typ Pos.marked UnionFind.elem) : unit =
  match Pos.unmark e with
  | EVar v -> (
      match A.VarMap.find_opt (Pos.unmark v) env with
      | Some tau' -> ignore (unify tau (UnionFind.make tau'))
      | None ->
          Errors.raise_spanned_error "Variable not found in the current context"
            (Pos.get_position e) )
  | ELit (LBool _) -> unify tau (UnionFind.make (Pos.same_pos_as (TLit TBool) e))
  | ELit (LInt _) -> unify tau (UnionFind.make (Pos.same_pos_as (TLit TInt) e))
  | ELit (LRat _) -> unify tau (UnionFind.make (Pos.same_pos_as (TLit TRat) e))
  | ELit (LMoney _) -> unify tau (UnionFind.make (Pos.same_pos_as (TLit TMoney) e))
  | ELit (LDate _) -> unify tau (UnionFind.make (Pos.same_pos_as (TLit TDate) e))
  | ELit (LDuration _) -> unify tau (UnionFind.make (Pos.same_pos_as (TLit TDuration) e))
  | ELit LUnit -> unify tau (UnionFind.make (Pos.same_pos_as (TLit TUnit) e))
  | ELit LEmptyError -> unify tau (UnionFind.make (Pos.same_pos_as TAny e))
  | ETuple es -> (
      let tau' = UnionFind.get (UnionFind.find tau) in
      match Pos.unmark tau' with
      | TTuple ts -> List.iter2 (fun (e, _) t -> typecheck_expr_top_down env e t) es ts
      | TAny ->
          unify tau
            (UnionFind.make
               (Pos.same_pos_as
                  (TTuple (List.map (fun (arg, _) -> typecheck_expr_bottom_up env arg) es))
                  e))
      | _ ->
          Errors.raise_spanned_error
            (Format.asprintf "expected %a, got a tuple" format_typ tau)
            (Pos.get_position e) )
  | ETupleAccess (e1, n, _) -> (
      let t1 = typecheck_expr_bottom_up env e1 in
      match Pos.unmark (UnionFind.get (UnionFind.find t1)) with
      | TTuple t1s -> (
          match List.nth_opt t1s n with
          | Some t1n -> unify t1n tau
          | None ->
              Errors.raise_spanned_error
                (Format.asprintf
                   "expression should have a tuple type with at least %d elements but only has %d" n
                   (List.length t1s))
                (Pos.get_position e1) )
      | TAny ->
          (* Include total number of cases in ETupleAccess to continue typechecking at this point *)
          Errors.raise_spanned_error
            "The precise type of this expression cannot be inferred.\n\
             Please raise an issue one https://github.com/CatalaLang/catala/issues"
            (Pos.get_position e1)
      | _ ->
          Errors.raise_spanned_error
            (Format.asprintf "expected a tuple , got %a" format_typ tau)
            (Pos.get_position e) )
  | EInj (e1, n, _, ts) ->
      let ts = List.map (fun t -> UnionFind.make (Pos.map_under_mark ast_to_typ t)) ts in
      let ts_n =
        match List.nth_opt ts n with
        | Some ts_n -> ts_n
        | None ->
            Errors.raise_spanned_error
              (Format.asprintf
                 "Expression should have a sum type with at least %d cases but only has %d" n
                 (List.length ts))
              (Pos.get_position e)
      in
      typecheck_expr_top_down env e1 ts_n;
      unify (UnionFind.make (Pos.same_pos_as (TEnum ts) e)) tau
  | EMatch (e1, es) ->
      let enum_cases = List.map (fun (e', _) -> UnionFind.make (Pos.same_pos_as TAny e')) es in
      let t_e1 = UnionFind.make (Pos.same_pos_as (TEnum enum_cases) e1) in
      typecheck_expr_top_down env e1 t_e1;
      let t_ret = UnionFind.make (Pos.same_pos_as TAny e) in
      List.iteri
        (fun i (es', _) ->
          let enum_t = List.nth enum_cases i in
          let t_es' = UnionFind.make (Pos.same_pos_as (TArrow (enum_t, t_ret)) es') in
          typecheck_expr_top_down env es' t_es')
        es;
      unify tau t_ret
  | EAbs (pos_binder, binder, t_args) ->
      let xs, body = Bindlib.unmbind binder in
      if Array.length xs = List.length t_args then
        let xstaus = List.map2 (fun x t_arg -> (x, t_arg)) (Array.to_list xs) t_args in
        let env =
          List.fold_left
            (fun env (x, t_arg) -> A.VarMap.add x (ast_to_typ (Pos.unmark t_arg), pos_binder) env)
            env xstaus
        in
        let t_out = typecheck_expr_bottom_up env body in
        let t_func =
          List.fold_right
            (fun t_arg acc ->
              UnionFind.make
                (Pos.same_pos_as
                   (TArrow (UnionFind.make (ast_to_typ (Pos.unmark t_arg), pos_binder), acc))
                   e))
            t_args t_out
        in
        unify t_func tau
      else
        Errors.raise_spanned_error
          (Format.asprintf "function has %d variables but was supplied %d types" (Array.length xs)
             (List.length t_args))
          pos_binder
  | EApp (e1, args) ->
      let t_args = List.map (typecheck_expr_bottom_up env) args in
      let te1 = typecheck_expr_bottom_up env e1 in
      let t_func =
        List.fold_right
          (fun t_arg acc -> UnionFind.make (Pos.same_pos_as (TArrow (t_arg, acc)) e))
          t_args tau
      in
      unify te1 t_func
  | EOp op ->
      let op_typ = op_type (Pos.same_pos_as op e) in
      unify op_typ tau
  | EDefault (excepts, just, cons) ->
      typecheck_expr_top_down env just (UnionFind.make (Pos.same_pos_as (TLit TBool) just));
      typecheck_expr_top_down env cons tau;
      List.iter (fun except -> typecheck_expr_top_down env except tau) excepts
  | EIfThenElse (cond, et, ef) ->
      typecheck_expr_top_down env cond (UnionFind.make (Pos.same_pos_as (TLit TBool) cond));
      typecheck_expr_top_down env et tau;
      typecheck_expr_top_down env ef tau
  | EAssert e' ->
      typecheck_expr_top_down env e' (UnionFind.make (Pos.same_pos_as (TLit TBool) e'));
      unify tau (UnionFind.make (Pos.same_pos_as (TLit TUnit) e'))

(** {1 API} *)

(* Infer the type of an expression *)
let infer_type (e : A.expr Pos.marked) : A.typ Pos.marked =
  let ty = typecheck_expr_bottom_up A.VarMap.empty e in
  typ_to_ast ty

(** Typechecks an expression given an expected type *)
let check_type (e : A.expr Pos.marked) (tau : A.typ Pos.marked) =
  typecheck_expr_top_down A.VarMap.empty e (UnionFind.make (Pos.map_under_mark ast_to_typ tau))
