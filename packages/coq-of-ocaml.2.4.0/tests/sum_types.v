Require Import CoqOfOCaml.CoqOfOCaml.
Require Import CoqOfOCaml.Settings.

Inductive t1 : Set :=
| C1 : int -> t1
| C2 : bool -> int -> t1
| C3 : t1.

Definition n : t1 := C2 false 3.

Definition m : bool :=
  match n with
  | C2 b _ => b
  | _ => true
  end.

Inductive t2 (a : Set) : Set :=
| D1 : t2 a
| D2 : a -> t2 a -> t2 a.

Arguments D1 {_}.
Arguments D2 {_}.

Fixpoint of_list {A : Set} (l : list A) : t2 A :=
  match l with
  | [] => D1
  | cons x xs => D2 x (of_list xs)
  end.

Fixpoint sum (l : t2 int) : int :=
  match l with
  | D1 => 0
  | D2 x xs => Z.add x (sum xs)
  end.

Definition s {A : Set} (function_parameter : A) : int :=
  let '_ := function_parameter in
  sum (of_list [ 5; 7; 3 ]).

Parameter t3 : Set.

Parameter t4 : forall (a : Set), Set.

Inductive t5 : Set :=
| C : t5.

Inductive single_string : Set :=
| Single : string -> single_string.

Definition get_string (s : single_string) : string :=
  let 'Single s := s in
  s.
