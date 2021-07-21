(** EXPANSION : main

------------------------------------------------------------

L'expansion consiste essentiellement � construire 3 tables globales
index�es par des ident target :

- Table des variables (support) : elle contient les entr�es/sorties
  et les locales (cf. exist) remont�es au top via un nommage unique.

- Table des alias : associe � des idents cible des expressions alg�briques.
    Les idents cible correpondent au instances de macros utilis�es
    dans le corps du node.

- Table des traces : � chaque trace nomm�e est associ�e une expression
  de trace expans�e.

- Table des fonctions externes utilisees, pour + tard 

----------------------------------------------------------*)


(** Les param�tres de l'expansion sont :
-------------------------------------------------------
- Le CheckEnv.t qui r�sulte du type/binding check.
    Il permet de retrouver le type effectif (s�mantique)
    de toute expression source et l'info associ�e � toute
    instance d'identificateur.
-------------------------------------------------------
- Le code source (type Syntaxe.package)
-------------------------------------------------------
- Le node "main" (string)
-------------------------------------------------------
*)

(** Le r�sultat de l'expansion consiste en 3 tables index�es 
    par des idents cibles (CoIdent.t) :
    - Table des variables (support)
    - Table des alias (d'expressions alg�briques)
    - + la liste d'alias
    - Table des traces
*)

(** Info et table des variables support
*)
type support_scope

type support_nature =
  | Input
  | Output
  | LocalIn
  | LocalOut
    
type support_info = {
	si_ident : CoIdent.t ;
   si_nature : support_nature ;
   si_type : CkTypeEff.t ;
   si_ref_exp : CoAlgExp.t ;
   si_src : CoIdent.src_stack;
   (* on ne la cr�e qu'� la demande *)
   si_pre_ref_exp : CoAlgExp.t option ;
   si_default : CoAlgExp.t option ;
   si_scope : support_scope option ;
   si_init  : CoAlgExp.t option ;
   si_range  : (CoAlgExp.t *CoAlgExp.t) option ;
}
(* Le type "r�sultat d'expansion" est abstrait *)
(* type t *)
and t
  
open Util
(* support_info that are actually used in pre's *)
val support_tab : t -> support_info StringMap.t 

(* support_info that are actually used in pre's *)
val support_pres : t -> (CoIdent.t * support_info) list

val input_list : t -> CoIdent.t list
val output_list : t -> CoIdent.t list
val local_in_list : t -> CoIdent.t list
val local_out_list : t -> CoIdent.t list

val ident_space : t -> CoIdent.space


val node_name : t -> string

(** Info et table des alias alg�briques *)
type alias_info = {
	ai_type : CkTypeEff.t;
	ai_def_exp : CoAlgExp.t;
	ai_ref_exp : CoAlgExp.t;
	ai_src : CoIdent.src_stack
}

val alias_tab : t -> alias_info StringMap.t
val alias_list : t -> CoIdent.t list

(* Run tab *)
(* not necessary ?
val run_tab : t -> (CoIdent.t, t) StringMap.t
*)

val get_run_expanded_code : t -> CoIdent.t -> t

(** Info et table des alias trace *)

type tbl = {
  arg_opt: MainArg.t;
  expanded_code: t;
  (* translation CoIdent -> Exp.var is done once *)
  in_vars: Exp.var list;
  out_vars: Exp.var list;
  loc_vars: Exp.var list;
  (* (partial) initial values of global vars (ins/outs *)
  init_pres: Value.OfIdent.t;

  id2var_tab: Exp.var Util.StringMap.t;

  (* REQUIRED BY SolveR.solve_formula *)
  (* list of names for outputs ... *)
  out_var_names: string list;
  (* ... formula (and) for bool vars ... *)
  bool_vars_to_gen: Exp.formula;
  (* ... and var list for nums ! *)
  num_vars_to_gen: Exp.var list;
  snt: Solver.t;
}

and trace_info = {
	ti_def_exp : tbl CoTraceExp.t;
	ti_src : CoIdent.src_stack ;
}

val make : CheckEnv.t -> Syntaxe.package -> string -> t
val trace_tab : t -> trace_info StringMap.t

val get_trace_info : t -> CoIdent.t -> trace_info

(** Info et table des externes utilis�es
	on garde le CkIdentInfo.t tel quel pour
	usage ult�rieur (g�n�ration de code)
	N.B. le source est un lexeme
*)

type extern_info = {
   xi_decl : Syntaxe.let_info;
   xi_prof : CkTypeEff.profile;
   xi_src : Lexeme.t
}

val extern_tab : t -> extern_info StringMap.t

(** Identificateur (target) de la trace principale *)
val main_trace : t -> CoIdent.t

(** DUMP pour debug etc. *)
val dump : t -> unit
val dump_src_ctx : t -> string
