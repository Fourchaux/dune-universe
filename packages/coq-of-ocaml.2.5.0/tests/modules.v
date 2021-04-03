Require Import CoqOfOCaml.CoqOfOCaml.
Require Import CoqOfOCaml.Settings.

Module List2.
  Inductive t (a : Set) : Set :=
  | Nil : t a
  | Cons : a -> t a -> t a.
  
  Arguments Nil {_}.
  Arguments Cons {_}.
  
  Fixpoint sum (l : t int) : int :=
    match l with
    | Nil => 0
    | Cons x xs => Z.add x (sum xs)
    end.
  
  Fixpoint of_list {A : Set} (function_parameter : list A) : t A :=
    match function_parameter with
    | [] => Nil
    | cons x xs => Cons x (of_list xs)
    end.
  
  Module Inside.
    Definition x : int := 12.
  End Inside.
End List2.

Definition n {A : Set} (function_parameter : A) : int :=
  let '_ := function_parameter in
  List2.sum (List2.of_list [ 5; 7; 6; List2.Inside.x ]).

Module Syn := List2.Inside.

Definition xx : int := Syn.x.
