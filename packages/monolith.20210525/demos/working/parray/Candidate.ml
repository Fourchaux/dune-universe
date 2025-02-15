(******************************************************************************)
(*                                                                            *)
(*                                  Monolith                                  *)
(*                                                                            *)
(*                              François Pottier                              *)
(*                                                                            *)
(*  Copyright Inria. All rights reserved. This file is distributed under the  *)
(*  terms of the GNU Lesser General Public License as published by the Free   *)
(*  Software Foundation, either version 3 of the License, or (at your         *)
(*  option) any later version, as described in the file LICENSE.              *)
(*                                                                            *)
(******************************************************************************)

(* These are Jean-Christophe Filliâtre's persistent arrays. *)

(* Persistent arrays implemented using Backer's trick.

   A persistent array is a usual array (node Array) or a change into
   another persistent array (node Diff). Invariant: any persistent array is a
   (possibly empty) linked list of Diff nodes ending on an Array node.

   As soon as we try to access a Diff, we reverse the linked list to move
   the Array node to the position we are accessing; this is achieved with
   the reroot function.
*)

type 'a t = 'a data ref
and 'a data =
  | Array of 'a array
  | Diff of int * 'a * 'a t

let make n v = ref (Array (Array.make n v))

let init n f = ref (Array (Array.init n f))

let rec rerootk t k = match !t with
  | Array _ -> k ()
  | Diff (i, v, t') ->
      rerootk t' (fun () -> begin match !t' with
		   | Array a as n ->
		       let v' = a.(i) in
		       a.(i) <- v;
		       t := n;
		       t' := Diff (i, v', t)
		   | Diff _ -> assert false end; k())

let reroot t = rerootk t (fun () -> ())

let get t i = match !t with
  | Array a ->
      a.(i)
  | Diff _ ->
      reroot t;
      begin match !t with Array a -> a.(i) | Diff _ -> assert false end

let set t i v =
  reroot t;
  match !t with
  | Array a as n ->
      let old = a.(i) in
      if old == v then
	t
      else begin
	a.(i) <- v;
	let res = ref n in
	t := Diff (i, old, res);
	res
      end
  | Diff _ ->
      assert false

(* wrappers to apply an impure function from Array to a persistent array *)
let impure f t =
  reroot t;
  match !t with Array a -> f a | Diff _ -> assert false

let length t = impure Array.length t

let to_list t = impure Array.to_list t

let iter f t = impure (Array.iter f) t
let iteri f t = impure (Array.iteri f) t

let fold_left f acc t = impure (Array.fold_left f acc) t
let fold_right f t acc = impure (fun a -> Array.fold_right f a acc) t
