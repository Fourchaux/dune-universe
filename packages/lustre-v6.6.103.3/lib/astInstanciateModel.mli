(* Time-stamp: <modified the 26/02/2015 (at 13:44) by Erwan Jahier> *)

(** Create packages from Model instances.  *)

(** Une seule fonctionnalit� : transformer au niveau "quasi-syntaxique" des
instances de pack du style "package toto = titi(....)" en package "donn�",
SI BESOIN.

(i.e. pack_info -> pack_given)

----------------------------------------------------------------------*)

(**----------------------------------------------------------------------
DESCRIPTION :

Entr�e, deux tables d'infos syntaxique :
- une table ptab : (string, AstV6.pack_info srcflagged) Hashtbl.t 
- une table mtab : (string, AstV6.model_info srcflagged) Hashtbl.t 

Sortie, une table d'info de package expans�es :
- une table xptab : (string, t) Hashtbl.t

Fonctionnement :
On met en relation les couples (param formel, arg effectif) :

(type t, id/type_exp) : on cr�e l'alias "type t = id/type_exp",
  qu'on met � la fois dans les export et dans le body
  => LES D�CLARATIONS DE TYPES SONT EXPORT�ES

(const c : t, id/val_exp) : on cr�e l'alias "const c : t = id/val_exp",
  qu'on met � la fois dans les export et dans le body
  => LES D�CLARATIONS DE CONST SONT EXPORT�ES

(node n(..)returns(...), id/node_exp) :
  - on garde le noeud "abstrait" dans export => node n(..)returns(...)
  - on d�finit l'alias "node n(..)returns(...) = id/node_exp" dans body


----------------------------------------------------------------------*)



(* ZZZ remplit AstTab.t par effet de bords. *)
val f : 
  (* la table des sources de modeles *)
  (Lv6Id.t, AstV6.model_info Lxm.srcflagged) Hashtbl.t ->
  (* la def de pack � traiter *)
  (AstV6.pack_info  Lxm.srcflagged) ->
  AstV6.pack_given

