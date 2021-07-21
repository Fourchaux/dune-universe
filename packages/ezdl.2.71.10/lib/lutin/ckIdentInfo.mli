(** TYPE/BINDING CHECK : infos associ�es aux idents

------------------------------------------------------------

Information attach�es idents au cours du type/binding check 

N.B. les exceptions ont trait�s
comme des constantes abstraites de type CkTypeEff.except

----------------------------------------------------------*)

(***********************************************************)

(* devrait etre abstrait ...
type t

type nature =
   Formal_param
|  Support_var
|  Const_ident
|  Def_ident of Syntaxe.let_info
|  Macro_ident of (Syntaxe.let_info option * CkTypeEff.profile)
*)

type extern_info = {
	ed_lib_name: string;
	ed_lib_desc: Ezdl.t;
	ed_sym: Ezdl.cfunc;
}

type t = {
   ii_name : string;
   ii_def_ident : Syntaxe.ident option;
   ii_nature : nature ;
	(* result type(s) for macros (nodes) *)
   ii_type : CkTypeEff.t list ;
	ii_hideable : bool;
} and nature =
   Formal_param
|  Support_var
|  Const_ident
|  Def_ident of Syntaxe.let_info
|  Macro_ident of (Syntaxe.let_info option * CkTypeEff.profile)
|  Node_ident of (Syntaxe.node_info option * CkTypeEff.profile)
|  External_func of (Syntaxe.let_info option * extern_info option * CkTypeEff.profile)


val get_nature : t -> nature
(* use it only when type is surely single *)
val get_type : t -> CkTypeEff.t

(* r�f�rence � un op�rateur ou d'une constante pr�d�finie *) 
val is_predef : t -> bool

(* r�f�rence � un op�rateur externe *) 
val is_extern : t -> bool

(* l'instance d'ident de la d�claration
	erreur si is_predef
*)
val def_ident : t -> Syntaxe.ident

(** CR�ATION DES INFOS *)

val of_support : Syntaxe.ident -> CkTypeEff.t -> t
val of_param : Syntaxe.ident -> CkTypeEff.t -> t

(** Les constantes abstraites peuvent �tre :
    - globales, auquels cas il est interdit de
    les re-d�finir localement
    - locales, auquels cas on a le droit de
    red�finir localement
*)

val of_global_cst : Syntaxe.ident -> CkTypeEff.t -> t

val of_local_cst : Syntaxe.ident -> CkTypeEff.t -> t

(** macro/alias : on garde toute les infos du let *)
val of_macro : Syntaxe.ident -> CkTypeEff.profile -> Syntaxe.let_info -> t
val of_alias : Syntaxe.ident -> CkTypeEff.t -> Syntaxe.let_info -> t

(** node *)
val of_node : Syntaxe.ident -> CkTypeEff.profile -> Syntaxe.node_info -> t

(** extern : cas simplifie du precedent *)
val of_extern : Syntaxe.ident -> CkTypeEff.profile -> Syntaxe.let_info -> extern_info option -> t

(** op�rateur pr�d�fini : juste un nom et un profil *) 
val of_predef_op : string -> CkTypeEff.profile -> t

(** constante pr�d�finie : juste un nom et un type *) 
val of_predef_cst : string -> CkTypeEff.t -> t


(* pretty print (pour debug) *)
val to_string : t -> string

(* est-elle "ecrasable" ? *)
val is_hideable : t -> bool
