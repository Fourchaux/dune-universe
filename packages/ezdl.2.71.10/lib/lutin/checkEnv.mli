(** TYPE/BINDING CHECK : environnement

C'est la structure qui permet :
- de r�aliser le type/binding check (cf. CheckType)
- de conserver, apr�s ce check, les infos calcul�es/inf�r�es

Toute r�f�rence � un identificateur est identifi�e
de mani�re UNIQUE par son ident (string + lexeme).

Au cours du check, on utilise TROIS tables :
- une table "dynamique" de scoping "string -> ident_info" 
  qui permet de r�soudre les r�f�rence sous "scope"
- une table GLOBALE de binding "ident -> ident_info"
  remplie au fur et � mesure que les r�f�rences sont r�solue
- une table de typage des "val_exp -> CkTypeEff.t"
  n.b. les val_exp SONT identifi�es de mani�re unique
  par leur lexeme

N.B. voir sous-module :
	CkTypeEff
	CkIdentInfo

N.B. Les identificateurs d'exceptions sont trait�s
comme des constantes abstraites de type CkTypeEff.except
-------------------------------------------------------------*)

type t

(************************************************)
(********** Cr�ation ****************************)
(************************************************)
val create : unit -> t 
val copy : t -> t 

(* add an external lib list *)
val add_libs : t -> string list -> t

(* If "None" libs (add_libs never called) returns None
	else returns a CkIdentInfo.extern_info describing
	the external binding 
internal !!
val get_in_libs : t -> Lexeme.t -> CkIdentInfo.extern_info option 
*)

(************************************************)
(********** Int�rogation ************************)
(************************************************)
(*
	N.B. Ne doivent �tre utilis�es QU'APRES le type/binding check !
	Toute erreur est forc�ment un BUG ! 
*)

(* Interogation du typing *)
val get_exp_type : t -> Syntaxe.val_exp -> CkTypeEff.t

(* Interogation du binding *)
val get_binding : t -> Syntaxe.ident -> CkIdentInfo.t

(************************************************)
(********** Modification du typing ****************)
(************************************************)

(* ajout d'un exp <-> type *)
val set_exp_type : t -> Syntaxe.val_exp -> CkTypeEff.t -> unit

(************************************************)
(********** Modification du scope ****************)
(*
	Toutes les fonction renvoie une scope_key
   qu'il faut utiliser pour restaurer le scope.

	Les appels add_.../restore doivent �tre 
   correctement imbriqu�s !!
*)
(************************************************)

(* cl� pour restaurer le scope *)
type scope_key

(* restauration *)
val restore : t -> scope_key -> unit

type typed_ids = (Syntaxe.ident * Syntaxe.type_exp) list
type eff_typed_ids = (Syntaxe.ident * CkTypeEff.t) list

(* ajout de param�tres formels *)
val add_formal_params : t -> typed_ids option -> scope_key

(* ajout de variables support *)
val add_support_vars : t -> eff_typed_ids -> scope_key

(* ajout d'une constante abstraite *)
val add_global_cst : t ->
	Syntaxe.ident ->
	CkTypeEff.t ->
	scope_key

val add_local_cst : t ->
	Syntaxe.ident ->
	CkTypeEff.t ->
	scope_key


(* ajout d'un support de noeud *)
val add_support_profile :
	t -> eff_typed_ids -> eff_typed_ids -> scope_key

(* ajout d'un let x *)
val add_let : t ->
	Syntaxe.let_info ->
	CkTypeEff.t ->        (* type du resultat *)
	Syntaxe.ident ->
	scope_key

(* ajout d'un node x *)
val add_node : t ->
	Syntaxe.node_info ->
	CkTypeEff.profile ->  (* whole profile *)
	Syntaxe.ident ->
	scope_key

(* ajout d'un extern x *)
val add_extern : t ->
	Syntaxe.let_info ->
	CkTypeEff.t ->        (* type du resultat *)
	Syntaxe.ident ->
	scope_key

(* ajout d'un op predef *)
val add_predef_op : t ->
	string ->
	CkTypeEff.profile ->
	scope_key

(* ajout d'une constante predef *)
val add_predef_cst : t ->
	string ->
	CkTypeEff.t ->
	scope_key

(*********************************************)
(**** Interrogation de l'environnement *******)
(* Et ajout (�ventuel) d'un binding) 
 N.B. UNIQUEMENT POUR LA CONSTRUCTION :
pour l'int�rogation ult�rieure voir get_binding
********************************************)

val get_ident_info : t -> Syntaxe.ident -> CkIdentInfo.t

val nature_of_ident : t -> Syntaxe.ident -> CkIdentInfo.nature

val type_of_ident : t -> Syntaxe.ident -> CkTypeEff.t

(* dump pour debug *)
val dbg_dump : t -> unit


