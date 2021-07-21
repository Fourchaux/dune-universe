(** COMPILATION/EXPANSION : idents et retour au source

------------------------------------------------------------

Identificateurs et remont�e au source

C'est un peu du luxe, mais on distingue :

- les ident source, Syntaxe.ident (sous-entendu avec src_info, donc UNIQUES),

- les ident target (de simple string, mais uniques par construction).

N.B. �a a beau �tre de simple string, on en fait quand m�me
un type abstrait, au cas o� ...

----------------------------------------------------------*)

(**********************************************************)

(** remet le module a zero ... *)
type space
val new_space : unit -> space 

(** Ident dans target, unique par nommage *)
type t = string

val to_string : t -> string
val list_to_string : t list  -> string -> string

(** L'unicit� des idents target est garantie par la fonction suivante,
qui prend un pr�fixe en param�tre
*)
val get_fresh : space -> string -> t

(** Si on est s�r qu'il n'y aurra pas de probl�me, on peut
forcer un nom *)
val get : string -> t

(* specifique aux compteurs : pour �tre sur
   que le compteur no i a toujours le meme nom !
*)
val of_cpt : int -> t

(** Si le nom doit rester tel quel *)
val from_string : string -> t

(** REMONT�E AU SOURCE DANS LE PROGRAMME EXPANS� *)

(** Remont�e au source d'un "target" depuis le code expans� *)
type src_stack = (Lexeme.t * Lexeme.t * Syntaxe.val_exp option) list

(** Remont�e au source d'un scope depuis le code expans� *)
type scope_stack = (Lexeme.t * src_stack)


(** Scope de base *)
val main_scope : Lexeme.t -> scope_stack
val get_scope : Lexeme.t -> src_stack -> scope_stack 

val base_stack : unit -> src_stack

(** Avec un scope_stack et une instance de Syntaxe.ident,
    on fabrique un src_stack complet *)
val get_src_stack : Lexeme.t -> scope_stack -> Syntaxe.val_exp option -> src_stack

val print_src_stack : src_stack -> unit
val string_of_src_stack : src_stack -> string 
val head_of_src_stack : src_stack -> Lexeme.t 

