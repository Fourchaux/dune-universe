Require Import CoqOfOCaml.CoqOfOCaml.
Require Import CoqOfOCaml.Settings.

Module Sig1.
  Record signature {t : Set} : Set := {
    t := t;
    f : t -> t -> t * t;
  }.
End Sig1.

Module Sig2.
  Record signature {t : Set} : Set := {
    t := t;
    f : t -> list t;
  }.
End Sig2.

Module M1.
  Definition t : Set := int.
  
  Definition f {A B : Set} (n : A) (m : B) : A * B := (n, m).
  
  Definition module :=
    existT (A := Set) _ t
      {|
        Sig1.f := f
      |}.
End M1.
Definition M1 : {t : Set & Sig1.signature (t := t)} := M1.module.

Module M2.
  Definition t : Set := int.
  
  Definition f {A B : Set} (n : A) : list B := nil.
  
  Definition module :=
    existT (A := Set) _ t
      {|
        Sig2.f := f
      |}.
End M2.
Definition M2 : {t : Set & Sig2.signature (t := t)} := M2.module.
