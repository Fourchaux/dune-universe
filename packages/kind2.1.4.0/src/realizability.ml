(* This file is part of the Kind 2 model checker.

   Copyright (c) 2020-2021 by the Board of Trustees of the University of Iowa

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

module VS = Var.VarSet
module TSys = TransSys


type realizability_result =
  | Realizable of Term.t (* Fixpoint *)
  | Unrealizable
  | Unknown


let term_partition var_lst term_lst =
  let var_set = VS.of_list var_lst in
  term_lst |> List.partition (fun c ->
    VS.inter (Term.vars_of_term c) var_set
    |> VS.is_empty
  )


let rec get_conjucts term =
  match Term.destruct term with
  | Term.T.App (s, args) when s == Symbol.s_and ->
     List.map get_conjucts args |> List.flatten
  | _ -> [term]


let compute_and_print_core solver terms =
  let actlit_term_map =
    terms |> List.map (fun t ->
      let actlit_uf = Actlit.fresh_actlit () in
      SMTSolver.declare_fun solver actlit_uf;
      let actlit = Actlit.term_of_actlit actlit_uf in
      actlit, t
    )
  in

  let impls =
    List.map (fun (al, t) -> Term.mk_implies [al; t]) actlit_term_map
  in

  SMTSolver.assert_term solver (Term.mk_and impls) ;

  let unsat_core_lits =
    let actlits = List.map fst actlit_term_map in
    SMTSolver.check_sat_assuming solver
      (fun _ -> assert false)
      (fun _ -> SMTSolver.get_unsat_core_lits solver)
      actlits
  in

  let unsat_core_terms =
    unsat_core_lits |> List.map (fun l -> List.assoc l actlit_term_map)
  in

  Debug.contractck "@[<hv>Unsat core:@.@[<hv>%a@]@]@."
    (Lib.pp_print_list Term.pp_print_term "@,") unsat_core_terms


let compute_unsat_core sys context requirements ex_var_lst =
  let solver =
    SMTSolver.create_instance
      ~produce_cores:true
      ~produce_assignments:true
      ~minimize_cores:true
      (TSys.get_logic sys)
      (Flags.Smt.solver ())
  in

  TransSys.define_and_declare_of_bounds
    sys
    (SMTSolver.define_fun solver)
    (SMTSolver.declare_fun solver)
    (SMTSolver.declare_sort solver)
    Numeral.zero Numeral.one;

  SMTSolver.push solver ;

  SMTSolver.assert_term solver context ;

  assert (SMTSolver.check_sat solver) ;

  let model = SMTSolver.get_model solver in

  SMTSolver.pop solver ;

  let assigns =
    let ex_var_set = VS.of_list ex_var_lst in
    Model.to_list model
    |> List.filter (fun (v,_) -> VS.mem v ex_var_set |> not)
    |> List.map (fun (v, vl) -> 
      match vl with
      | Model.Term e -> Term.mk_eq [Term.mk_var v; e]
      | _ -> assert false)
  in

  let terms = List.rev_append assigns requirements in

  compute_and_print_core solver terms ;

  SMTSolver.delete_instance solver


let compute_unsat_core_if_debugging sys context requirements ex_var_lst =
  let debugging =
    let dflags = Flags.debug () in
    List.mem "all" dflags || List.mem "contractck" dflags
  in
  if debugging then
    compute_unsat_core sys context requirements ex_var_lst


let realizability_check
  sys controllable_vars_at_0 vars_at_1 controllable_vars_at_1 =
  
  (* Solver for term simplification *)
  let solver =
    SMTSolver.create_instance
      (TSys.get_logic sys)
      (Flags.Smt.solver ())
  in

  TransSys.define_and_declare_of_bounds
    sys
    (SMTSolver.define_fun solver)
    (SMTSolver.declare_fun solver)
    (SMTSolver.declare_sort solver)
    Numeral.zero Numeral.one;

  (*Format.printf "%a@." (TSys.pp_print_subsystems true) sys ;*)

  QE.set_ubound Numeral.one ;

  let free_of_controllable_vars_at_1, contains_controllable_vars_at_1 =
    let trans =
      let invars =
        (TransSys.invars_of_bound sys ~one_state_only:true Numeral.zero)
      in  
      Term.mk_and
        (TSys.trans_of_bound None sys Numeral.one :: invars)
    in
    (*let trans = TSys.trans_of_bound None sys Numeral.one in*)
    term_partition controllable_vars_at_1 (get_conjucts trans)
  in

  (*Format.printf "U: %a@."
    (Format.pp_print_list Term.pp_print_term) free_of_controllable_vars_at_1 ;
  Format.printf "C: %a@."
    (Format.pp_print_list Term.pp_print_term) contains_controllable_vars_at_1 ;*)

  (* free_of_uncontrollable_vars_at_1 will usually be the empty list,
     but it is possible to write an assumption that only contains
     previous values of variables
  *)
  let free_of_uncontrollable_vars_at_1, contains_uncontrollable_vars_at_1 =
    term_partition vars_at_1 free_of_controllable_vars_at_1
  in

  let free_of_controllable_vars_at_0, contains_controllable_vars_at_0 =
    let init = TSys.init_of_bound None sys Numeral.zero in
    term_partition controllable_vars_at_0 (get_conjucts init)
  in

  let uncontrollable_varset_is_non_empty =
    List.length controllable_vars_at_1 < List.length vars_at_1
  in

  let rec loop fp =

    let fp_at_1 = Term.bump_state Numeral.one fp in

    let premises = Term.mk_and (fp :: free_of_controllable_vars_at_1) in

    let conclusion = Term.mk_and (fp_at_1 :: contains_controllable_vars_at_1) in

    (*Format.printf "T: %a@." Term.pp_print_term premises ;
    Format.printf "C: %a@." Term.pp_print_term conclusion ;*)

    let ae_val_reponse =
      QE.ae_val sys premises controllable_vars_at_1 conclusion
    in

    match ae_val_reponse with
    | QE.Valid _ -> (

      Debug.contractck
        "@[<hv>Computed fixpoint:@ @[<hv>%a@]@]@." Term.pp_print_term fp ;

      let premises' = Term.mk_and free_of_controllable_vars_at_0 in

      let conclusion' = Term.mk_and (fp :: contains_controllable_vars_at_0) in

      let ae_val_reponse' =
        QE.ae_val sys premises' controllable_vars_at_0 conclusion'
      in

      match ae_val_reponse' with
      | QE.Valid _ -> Realizable fp
      | QE.Invalid valid_region -> (
        (*Debug.contractck
            "@[<hv>(INITIAL) Valid region:@ @[<hv>%a@]@]@."
            Term.pp_print_term valid_region ;*)

        let neg_region = SMTSolver.simplify_term solver (Term.negate valid_region) in

        let context = Term.mk_and [premises'; neg_region] in

        let requirements =
          (get_conjucts fp) @ contains_controllable_vars_at_0
        in

        compute_unsat_core_if_debugging
          sys context requirements controllable_vars_at_0 ;

        Unrealizable
      )

    )
    | QE.Invalid valid_region -> (

      Debug.contractck
        "@[<hv>Valid region:@ @[<hv>%a@]@]@." Term.pp_print_term valid_region ;

      if uncontrollable_varset_is_non_empty then (

        let premises' = Term.mk_and (fp :: free_of_uncontrollable_vars_at_1) in

        let neg_region = SMTSolver.simplify_term solver (Term.negate valid_region) in

        let conclusion' =
          Term.mk_and (neg_region :: contains_uncontrollable_vars_at_1)
        in

        let ae_val_reponse' = QE.ae_val sys premises' vars_at_1 conclusion' in

        match ae_val_reponse' with
        | QE.Valid _ -> (
          Debug.contractck "@[<hv>Violating region: true@]@." ;

          let context = Term.mk_and [premises'; conclusion'] in

          let requirements =
            (get_conjucts fp_at_1) @ contains_controllable_vars_at_1
          in

          compute_unsat_core_if_debugging
            sys context requirements controllable_vars_at_1 ;

          Unrealizable
        )
        | QE.Invalid violating_region -> (
          Debug.contractck
              "@[<hv>Violating region:@ @[<hv>%a@]@]@."
              Term.pp_print_term violating_region ;

          let fp' =
            Term.mk_and [Term.negate violating_region; fp]
            |> SMTSolver.simplify_term solver
          in
          loop fp'
        )

      )
      else (

        let fp' =
          Term.mk_and [valid_region; fp]
          |> SMTSolver.simplify_term solver
        in
        loop fp'

      )
    )
  in

  let res = loop Term.t_true in

  QE.on_exit () ;

  res
