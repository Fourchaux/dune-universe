
(** {1 Propositional Literal} *)

open Mc2_core

module Fmt = CCFormat

type t = atom

let name = "propositional"
let neg = Atom.neg
let pp = Atom.pp

module F = Tseitin.Make(Atom)

(* add new case for terms *)
type term_view += Fresh of int

(* printer for terms *)
let pp out = function
  | Fresh i -> Fmt.fprintf out "_A%d" i
  | _ -> assert false

(* typeclass for terms *)
let t_tc : tc_term = Term.TC.make ~pp ()

let k_cnf = Service.Key.make "propositional.cnf"
let k_fresh = Service.Key.make "propositional.fresh"

let plugin =
  let build p_id Plugin.S_nil : Plugin.t =
    let module P : Plugin.S = struct
      let id = p_id
      let name = name
      (* term allocator *)
      module T_alloc = Term.Term_allocator(struct
          let tc = Term.TC.lazy_from_val t_tc
          let p_id = p_id
          let initial_size=64
          let[@inline] equal v1 v2 = match v1, v2 with
            | Fresh i, Fresh j -> i=j
            | _ -> assert false
          let[@inline] hash = function Fresh i -> CCHash.int i | _ -> assert false
        end)

      let check_if_sat _ = Sat

      let gc_all = T_alloc.gc_all
      let iter_terms = T_alloc.iter_terms

      let fresh : unit -> t =
        let n = ref 0 in
        fun () ->
          let view = Fresh !n in
          incr n;
          let t = T_alloc.make view Type.bool in
          Term.Bool.pa t

      let[@inline] cnf ?simplify (f:F.t) : t list list = F.cnf ~fresh ?simplify f

      let provided_services =
        [ Service.Any (k_fresh, fresh);
          Service.Any (k_cnf, cnf);
        ]
    end
    in
    (module P : Plugin.S)
  in
  Plugin.Factory.make ~priority:5 ~name ~requires:Plugin.K_nil ~build ()

