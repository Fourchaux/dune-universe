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

(** Clause, properties and activation literals for IC3

    @author Christoph Sticksel *)

(** Origin of clause *)
type source =
  | PropSet (** Clause is a pseudo clause for property set *)
  | BlockFrontier (** Negation of clause reaches a state outside the property in one step *)
  | BlockRec of t (** Negtion of clause reaches a state outside the
                      negation of the clause to block *)
  | IndGen of t (** Clause is an inductive generalization of the clause *)
  | CopyFwdProp of t  (** Clause is a copy of the clause from forward propagation *)
  | CopyBlockProp of t (** Clause is a copy of the clause from blocking in future frames *)
  | Copy of t (** Clause is a copy of the clause for another reason *)

(** Clause *)
and t


(** A trie of literals *)
module ClauseTrie : Trie.S with type key = Term.t list 

  
  
(** {1 Clauses} *)

(** For every clause [C = {L1, ..., Ln}] two activation literals [p0]
    and [p1] are generated per clause, in addition two activation
    literals [n0_i] and [n1_i] per literal Li. The following terms are
    then lazily asserted on the first access of the actiation:

    {[
    p0 => C
    p1 => C'
    n01 => ~L1
    n11 => ~L1'
    ...
    n0n => ~Ln
    n1n => ~Ln'
    ]}

    where the C' and Li' are the clause and the literals,
    respectively, at the next instant.
*)
  
(** Create a clause from a set of literals

    The activation literals are only created in the Kind 2 term
    database, but nothing is sent to the solver, instead they are only
    made on the first access of the activation literals in
    {!actlit_p0_of_clause}, {!actlit_p1_of_clause},
    {!actlits_n0_of_clause} and {!actlits_n1_of_clause}.
*)
val mk_clause_of_literals : source -> Term.t list -> t

(** Return a copy of the clause with fresh activation literal *)
val copy_clause_block_prop : t -> t
val copy_clause_fwd_prop : t -> t
val copy_clause : t -> t


(** Return unique identifier of clause *)
val id_of_clause : t -> int
  
(** Return the number of literals in the clause 

    Since duplicate literals are eliminated, this is not necessarily
    equal to the number of literals given when creating the clause. *)
val length_of_clause : t -> int

(** Return the conjunction of all literals in the clause *)
val term_of_clause : t -> Term.t

(** Return the literals in the clause 

    Since duplicate literals are eliminated and ordered, this is not
    necessarily equal to the list of literals given when creating the
    clause. *)
val literals_of_clause : t -> Term.t list

(** Return the source of the clause *)
val source_of_clause : t -> source 
  
(** {1 Activation Literals} *)
  
(** Return the activation literal for the positive unprimed clause 

    Declare the activation literal and assert the term [p0 => C] on
    the first access of the activation literal in the given solver
    instance. Fail with [Invalid_argument] if {!deactivate_clause} has
    been called for the clause in the given solver instance.
*)
val actlit_p0_of_clause : SMTSolver.t -> t -> Term.t

(** Return the activation literal for the positive primed clause 

    Declare the activation literal and assert the term [p1 => C'] on
    the first access of the activation literal in the given solver
    instance. Fail with [Invalid_argument] if {!deactivate_clause} has
    been called for the clause in the given solver instance.
*)
val actlit_p1_of_clause : SMTSolver.t -> t -> Term.t

(** Return the activation literals for the negated clause literals 

    Declare the activation literals and assert the terms [n0_i => L_i]
    for each literal [L_i] in the clause on the first access of the
    activation literal in the given solver instance. Fail with
    [Invalid_argument] if {!deactivate_clause} has been called for the
    clause in the given solver instance.
*)
val actlits_n0_of_clause : SMTSolver.t -> t -> Term.t list

(** Return the activation literals for the negated, primed literals

    Declare the activation literals and assert the terms [n1_i =>
    L_i'] for each literal [L_i] in the clause on the first access of
    the activation literal in the given solver instance. Fail with
    [Invalid_argument] if {!deactivate_clause} has been called for the
    clause in the given solver instance.
*)
val actlits_n1_of_clause : SMTSolver.t -> t -> Term.t list

(** Assert the negation of all activation literals of clause in the
    solver instance 

    The clause is marked as unusable in the solver instance, hence all
    calls to {!actlit_p0_of_clause}, {!actlit_p1_of_clause},
    {!actlits_n0_of_clause}, {!actlits_n1_of_clause} fail. *)
val deactivate_clause : SMTSolver.t -> t -> unit
  
(** If the clause is an inductive generalization, return the clause
    before generalization
    
    Only return one step of inductive generalization, repeat to obtain
    possible chains of generalizations. *)
val undo_ind_gen : t -> t option


(** {1 Property sets} *)

(** Set of properties *)
type prop_set

(** Create a property set from a list of named properties 

    The conjunction of properties is viewed as a single literal of a
    clause, and this clause is asserted with activation literals in
    the given solver instance. *)
val prop_set_of_props : (string * Term.t) list -> prop_set

(** Return the unit clause containing the conjunction of the
    properties as a literals *)
val clause_of_prop_set : prop_set -> t

(** Return the conjunction of the properties *)
val term_of_prop_set : prop_set -> Term.t

(** Return the named properties of the property set *)
val props_of_prop_set : prop_set -> (string * Term.t) list
  
(** Return the activation literal for the positive conjunction of properties *)
val actlit_p0_of_prop_set : SMTSolver.t -> prop_set -> Term.t

(** Return the activation literal for the positive primed conjunction
    of properties *)
val actlit_p1_of_prop_set : SMTSolver.t -> prop_set -> Term.t
  
(** Return the (singleton list of) activation literals for the negated
    conjunction of properties *)
val actlits_n0_of_prop_set : SMTSolver.t -> prop_set -> Term.t list
  
(** Return the (singleton list of) activation literals for the negated
    primed conjunction of properties *)
val actlits_n1_of_prop_set : SMTSolver.t -> prop_set -> Term.t list
  
(** {1 Frames} *)

(** Create or return an activation literal for the given frame *)
val actlit_of_frame : int -> Term.t
  
(** Create or return the uninterpreted functoin symbol for the
    activation literal for the given frame *)
val actlit_symbol_of_frame : int -> UfSymbol.t

(** {1 Activation literals} *)

(** Type of activation literal *)
type actlit_type = 
  | Actlit_p0  (** positive unprimed *)
  | Actlit_n0  (** negative unprimed *)
  | Actlit_p1  (** positive primed *)
  | Actlit_n1  (** negative primed *)

  
(** Create a fresh activation literal, declare it in the solver, and
    assert a term guarded with it

    [create_and_assert_fresh_actlit s h t a] declares a fresh
    uninterpreted Boolean constant in the solver instance [s], and
    asserts the term [t] guarded by this activation literal in the
    same solver instance. The parameter [h] is a tag used to name the
    constant, together with a counter that is maintained per tag. *)
val create_and_assert_fresh_actlit : SMTSolver.t -> string -> Term.t -> actlit_type -> Term.t

  
(* 
   Local Variables:
   compile-command: "make -C .. -k"
   tuareg-interactive-program: "./kind2.top -I ./_build -I ./_build/SExpr"
   indent-tabs-mode: nil
   End: 
*)
