
(** {1 Linear Expressions} *)

open Mc2_core

module TM = Term.Map

type num = Q.t

type t = {
  const: num;
  terms: num TM.t;
}

let empty : t = { const=Q.zero; terms=TM.empty; }
let zero = empty

let[@inline] merge_ ~f_left ~f_right ~fboth a b : t = {
  const=fboth a.const b.const;
  terms=TM.merge_safe a.terms b.terms
      ~f:(fun _ -> function
        | `Left n -> Some (f_left n)
        | `Right n -> Some (f_right n)
        | `Both (n1,n2) ->
          let n = fboth n1 n2 in
          if Q.sign n=0 then None else Some n);
}

let[@inline] add a b : t =
  merge_ a b ~f_left:(fun x->x) ~f_right:(fun x->x) ~fboth:Q.add

let[@inline] diff a b : t =
  merge_ a b ~f_left:(fun x->x) ~f_right:Q.neg ~fboth:Q.sub

let[@inline] equal e1 e2 : bool =
  Q.equal e1.const e2.const &&
  TM.equal Q.equal e1.terms e2.terms

let[@inline] hash_q (n:Q.t) : int =
  CCHash.combine2 (Z.hash @@ Q.num n) (Z.hash @@ Q.den n)

let[@inline] hash (e:t) : int =
  let hash_pair (t,n) = CCHash.combine3 11 (Term.hash t) (hash_q n) in
  CCHash.combine3 42 (hash_q e.const) (CCHash.iter hash_pair @@ TM.to_iter e.terms)

let[@inline] const n : t = {const=n; terms=TM.empty }
let[@inline] is_const n : bool = TM.is_empty n.terms
let[@inline] is_zero n : bool = is_const n && Q.sign n.const=0

let[@inline] as_singleton (e:t) =
  if Q.sign e.const = 0 && not (TM.is_empty e.terms) then (
    let t, n = TM.choose e.terms in
    if TM.is_empty (TM.remove t e.terms)
    then Some (n, t)
    else None
  ) else None

let[@inline] mem_term t e = TM.mem t e.terms
let[@inline] find_term_exn t e = TM.find t e.terms
let[@inline] get_term t e = TM.get t e.terms

let[@inline] mult n e : t =
  if Q.sign n=0 then empty
  else {
    const=Q.mul n e.const;
    terms= TM.map (Q.mul n) e.terms;
  }

let[@inline] neg e : t = mult Q.minus_one e

let[@inline] div e n : t =
  if Q.sign n=0 then raise Division_by_zero
  else {
    const=Q.div e.const n;
    terms=TM.map (fun x -> Q.div x n) e.terms;
  }

let add_term (n:num) (t:term) (e:t) : t =
  if Q.sign n=0 then e
  else (
    try
      let n' = TM.find t e.terms in
      let n = Q.add n n' in
      if Q.sign n=0 then {e with terms=TM.remove t e.terms}
      else {e with terms=TM.add t n e.terms}
    with Not_found ->
      {e with terms=TM.add t n e.terms}
  )

let[@inline] remove_term (t:term) (e:t) : t =
  if is_const e then e
  else {e with terms=TM.remove t e.terms}

let[@inline] singleton n t = add_term n t empty
let[@inline] singleton1 t = singleton Q.one t

let simplify (e:t) : t =
  match as_singleton e with
  | None -> e
  | Some (n,t) ->
    let n = if Q.sign n >= 0 then Q.one else Q.minus_one in
    singleton n t

let pp_no_paren out (e:t) : unit =
  if is_const e then Q.pp_print out e.const
  else (
    let pp_const out e =
      if Q.sign e.const=0 then () else Fmt.fprintf out " + %a" Q.pp_print e.const
    and pp_pair out (t,n) =
      assert (Q.sign n<>0);
      if Q.equal n Q.one then Term.pp out t
      else if Q.equal n Q.minus_one then Fmt.fprintf out "-%a" Term.pp t
      else Fmt.fprintf out "%a·%a" Q.pp_print n Term.pp t
    in
    Fmt.fprintf out "%a%a"
      (Util.pp_iter ~sep: " + " pp_pair) (TM.to_iter e.terms) pp_const e
  )

let[@inline] pp out e = Fmt.fprintf out "(@[%a@])" pp_no_paren e

let singleton_term (e:t) : term =
  if not (TM.is_empty e.terms) then (
    let t, _ = TM.choose e.terms in
    if equal e @@ singleton1 t then
      t
    else
      Error.errorf "LE is supposed to be only one term but is %a" pp e
  ) else (
    Error.errorf "LE is supposed to be only one term but is %a" pp e
  )

let flatten ~(f:term -> t option) (e:t) : t =
  TM.fold
    (fun t n_t e' ->
       begin match f t with
         | None -> add_term n_t t e'
         | Some sub_e ->
           add (mult n_t sub_e) e'
       end)
    e.terms (const e.const)

let[@inline] terms (e:t) = TM.keys e.terms
let[@inline] terms_l (e:t) = TM.keys e.terms |> Iter.to_rev_list

let[@inline] as_const (e:t) =
  if TM.is_empty e.terms then Some e.const
  else None

let eval_full_ ~f (e:t) : (num * term list) option =
  try
    let n, l =
      TM.fold
        (fun t n_t (sum,l) -> match f t with
           | None -> raise Exit
           | Some q -> Q.add (Q.mul n_t q) sum, t::l)
        e.terms (e.const,[])
    in
    Some (n,l)
  with Exit ->
    None

let[@inline] eval ~f e : _ option =
  if is_const e then Some (e.const, [])
  else eval_full_ ~f e

module Infix = struct
  let (+..) = add
  let (-..) = diff
  let ( *..) = mult
end
