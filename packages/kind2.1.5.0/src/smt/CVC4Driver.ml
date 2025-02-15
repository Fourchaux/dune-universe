(* This file is part of the Kind 2 model checker.

   Copyright (c) 2015 by the Board of Trustees of the University of Iowa

   Licensed under the Apache License, Version 2.0 (the "License"); you
   may not use this file except in compliance with the License.  You
   may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0 

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
   implied. See the License for the specific language governing
   permissions and limitations under the License. 

*)

include GenericSMTLIBDriver

(* Configuration for CVC4 *)
let cmd_line
    _ (* logic *)
    timeout
    _ (* produce_assignments *) 
    _ (* produce_proofs *)
    _ (* produce_cores *)
    _ (* minimize_cores *) 
    _ (* produce_interpolants *) =
  
  (* Path and name of CVC4 executable *)
  let cvc4_bin = Flags.Smt.cvc4_bin () in

  let incr_mode = "--incremental" in (* "--tear-down-incremental=1" *)

  let common_flags =
    [| incr_mode;
       "--decision=internal";
       "--ext-rew-prep";
       "--ext-rew-prep-agg" |]
    |> (
    if Flags.Smt.cvc4_rewrite_divk () then
      Array.append
        [|"--rewrite-divk"|] (* Allows division by constant in QF_LIA problems *)
    else
      Lib.identity
    ) |> (
    if Flags.Smt.cvc4_bv_consts_in_binary () then
      Array.append
        [|"--bv-print-consts-in-binary"|] (* Outputs BV constant as binary values *)
    else
      Lib.identity
    )
  in

  (*
  let fmfint_flags = [||] in (*
    [| "--fmf-bound-int";
       "--fmf-inst-engine";
       "--quant-cf";
       "--uf-ss-fair"|] in*)

  let fmfrec_flags = [||] in (*
    [| "--finite-model-find";
       "--macros-quant";
       "--fmf-inst-engine";
       "--fmf-fun";
       "--quant-cf";
       "--uf-ss-fair"|] in*)

  let inst_flags = match logic, Flags.Arrays.recdef () with
    | `Inferred l, true when FeatureSet.mem A l -> fmfrec_flags
    | `Inferred l, false when FeatureSet.mem A l -> fmfint_flags
    | `Inferred _, _ -> [||]
    | _, true -> fmfrec_flags
    | _, false -> fmfint_flags in*)

  let base_cmd = [| cvc4_bin; "--lang"; "smt2" |] in

  (* Timeout based on Flags.timeout_wall has been disabled because
     it seems to cause performance regressions on some models... *)
  let timeout_global = None
  (*  if Flags.timeout_wall () > 0.
    then Some (Stat.remaining_timeout () +. 1.0)
    else None*)
  in
  let timeout_local =
    if timeout > 0
    then Some (float_of_int timeout)
    else None
  in
  let timeout = Lib.min_option timeout_global timeout_local in

  let cmd =
    match timeout with
    | None -> base_cmd
    | Some timeout ->
      let timeout =
        Format.sprintf "--tlimit=%.0f" ((1000.0 *. timeout) |> ceil)
      in
      Array.append base_cmd [|timeout|]
  in

  Array.concat [cmd; common_flags]
  

let check_sat_limited_cmd _ = 
  failwith "check-sat with timeout not implemented for CVC4"


let s_lambda = HString.mk_hstring "LAMBDA"

let cvc4_expr_or_lambda_of_string_sexpr' ({ s_define_fun } as conv) bound_vars = 

  function 

    (* (define-fun c () Bool t) *)
    | HStringSExpr.List 
        [HStringSExpr.Atom s; (* define-fun *)
         HStringSExpr.Atom _; (* identifier *)
         HStringSExpr.List []; (* Parameters *)
         _; (* Result type *)
         t (* Expression *)
        ]
      when s == s_define_fun -> 

      Model.Term
        (gen_expr_of_string_sexpr' conv bound_vars t)


    (* (LAMBDA c () Bool t) *)
    | HStringSExpr.List 
        [HStringSExpr.Atom s; (* define-fun *)
         HStringSExpr.List []; (* Parameters *)
         _; (* Result type *)
         t (* Expression *)
        ]
      when s == s_lambda -> 

      Model.Term
        (gen_expr_of_string_sexpr' conv bound_vars t)


    (* (define-fun A ((x1 Int) (x2 Int)) Bool t) *)
    | HStringSExpr.List 
        [HStringSExpr.Atom s; (* define-fun *)
         HStringSExpr.Atom _; (* identifier *)
         HStringSExpr.List v; (* Parameters *)
         _; (* Result type *)
         t (* Expression *)
        ]
      when s == s_define_fun -> 

      (* Get list of variables bound by the quantifier *)
      let vars = gen_bound_vars_of_string_sexpr conv bound_vars [] v in

      (* Convert bindings to an association list from strings to
         variables *)
      let bound_vars' = 
        List.map 
          (function v -> (Var.hstring_of_free_var v, v))
          vars
      in

      Model.Lambda
        (Term.mk_lambda
           vars
           (gen_expr_of_string_sexpr' conv (bound_vars @ bound_vars') t))


    (* (LAMBDA ((_ufmt_1 Int) (_ufmt_2 Int)) (ite (= _ufmt_1 0) (= _ufmt_2 0) false)) *)
    | HStringSExpr.List 
        [HStringSExpr.Atom s; (* LAMBDA *)
         HStringSExpr.List v; (* Parameters *)
         t (* Expression *)
        ]
      when s == s_lambda -> 

      (* Get list of variables bound by the quantifier *)
      let vars = gen_bound_vars_of_string_sexpr conv bound_vars [] v in

      (* Convert bindings to an association list from strings to
         variables *)
      let bound_vars' = 
        List.map 
          (function v -> (Var.hstring_of_free_var v, v))
          vars
      in

      Model.Lambda
        (Term.mk_lambda
           vars
           (gen_expr_of_string_sexpr' conv (bound_vars @ bound_vars') t))

    (* Interpret as a term *)
    | _ -> invalid_arg "cvc4_expr_or_lambda_of_string_sexpr"

      

let lambda_of_string_sexpr = 
  gen_expr_or_lambda_of_string_sexpr smtlib_string_sexpr_conv


let string_of_logic l =
  let open TermLib in
  let open TermLib.FeatureSet in
  match l with
  (* Avoid theory overheads *)
  | `Inferred l when is_empty l -> "QF_SAT"
  (* CVC4 fails to give model when given a non linear arithmetic logic *)
  (*| `Inferred l when mem NA l -> "ALL"*)
  | `Inferred l when equal l (singleton Q) -> "LIRA" (* Only L*A supports quantifiers *)
  | _ -> GenericSMTLIBDriver.string_of_logic l

let pp_print_logic fmt l = Format.pp_print_string fmt (string_of_logic l)
