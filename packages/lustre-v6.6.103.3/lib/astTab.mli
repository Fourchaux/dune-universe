(* Time-stamp: <modified the 29/08/2019 (at 14:53) by Erwan Jahier> *)

(** Tabulated version of the parse tree.

  - cr��e � partir de la liste des pack/modeles
  - s'occupe de l'instanciation (purement syntaxique) des modeles
  - cr�e pour chaque pack provided la liste ``brute'' des noms d'items
  export�s. Cette liste sera importante pour traiter les "use" lors de
  la cr�ation des tables de symboles de chaque pack
*)

type t

val create : AstV6.pack_or_model list -> t


(** acc�s aux infos *)
val pack_body_env : t -> Lv6Id.pack_name -> AstTabSymbol.t

(** A package may have no provided part *)
val pack_prov_env : t -> Lv6Id.pack_name -> AstTabSymbol.t option

(** Liste des noms de packs *)
val pack_list : t -> Lv6Id.pack_name list 

(** For debug.  *)
val dump : t -> unit

