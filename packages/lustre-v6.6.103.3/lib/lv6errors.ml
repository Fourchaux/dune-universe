(* Time-stamp: <modified the 15/03/2021 (at 12:22) by Erwan Jahier> *)

(** *)

(** Exceptions et formatage des messages d'erreur.

	La compilation peut �chouer sur des exceptions pr�d�finies :

	- Sys_error of string :
	-----------------------
	erreur syst�me (li�e aux fichiers)

	- Parse_error :
	---------------
	dans le yacc

	- Compile_error of Lxm.t * string :
	--------------------------------------
	une erreur de compil qu'on peut "situer" dans le source gr�ce
	� un lexeme *

	- Global_error of string :
	--------------------------
	une erreur qui n'est pas sp�cialement li�e � un lexeme,
	(mais peut-�tre li�e � un noeud -> void checkNode) *

	- Compile_node_error of Lic.node_key * Lxm.t * string :
	------------------------------------------------------------------
	une erreur de compil li�e � un lexeme et � un noeud (en fait
	une instance de template) particulier * ** ***

	- Global_node_error of Lic.node_key * string :
	------------------------------------------------------------------
	une erreur de compil non li�e � un lexeme particulier,
	mais dependant lev�e lors de la compilation d'un noeud * ** ***

	* Les diff�rentes phases peuvent �ventuellement "capter"
	locallement les exceptions pr�c�dentes (histoire de sortir
	plus d'un message d'erreur par compilation).

	** Les erreurs li�es � un noeuds sont g�n�r�es UNIQUEMENT
	au niveau de checkNode => lors de la compil d'un noeud,
	les sous-proc�dures se contentent de lever des erreurs
	``simples'' (Global ou Compile), qui sont capt�es au niveau
	de checkNode o� on ``rajoute'' l'info sur le noeud
	courant (�a �vite de toujours passer en param�tre  le noeud courant).

	*** Pas d�fini ici (� cause des %@#&! problemes de compil s�par�e),
	voir Compile_data


----------------------------------------------------------------------
A titre indicatif, voici la liste des messages d'erreurs (actuels)
- Au lancement/chargement :

"can't load main node: <name> is undefined"
"can't load main node: <name> is a function"
"can't load main node: <name> is a template"

- Au cours du static check (toutes sont associ�es � un lexeme) :

"can't eval constant: <msg>"
"can't eval type: <msg>"

"recursion loop detected: <recursion path>"
"unbound type"
"undefined constant or variable"
"undefined node or function"
"undefined type"
"node expected but get a function"
"type combination error: <type> expected"
"arity error: <int> expected instead of <int>"
"operation not allowed in static expression: <operation>"
"array index '<int>' out of bounds '<int>..<int>"
"type error in array: <type> mixed with <type>"
"array of tuple not allowed"
"empty array"
"constant is declared as <type> but evaluated as <type>"
"bad constant value: tuple not allowed"
"field is declared as <type> but evluated as <type>"
"bad field value: tuple not allowed"
"bad static expression: <ident> is a variable"
"bad array size <int>"
"bad array size"

----------------------------------------------------------------------*)

(** ---------------------------------------------------------------------
Une erreur associ�e � un lexeme dans le fichier source
----------------------------------------------------------------------*)
exception Compile_error of Lxm.t * string

exception Unknown_constant of Lxm.t * string
exception Unknown_var of Lxm.t * Lv6Id.t

(** ---------------------------------------------------------------------
Une erreur plus generale
----------------------------------------------------------------------*)
exception Global_error of string


(** ---------------------------------------------------------------------
Formatage standard des erreurs de compil
----------------------------------------------------------------------*)
let compile_error_string lxm msg = (
   Printf.sprintf "\nError: %s:\nError: %s\n" (Lxm.details lxm) msg
)
let runtime_error_string lxm msg = (
   Printf.sprintf "\nRuntime Error: %s:\nError: %s\n" (Lxm.details lxm) msg
)

(** ---------------------------------------------------------------------
Message d'erreur (associ� � un lexeme) sur stderr
----------------------------------------------------------------------*)
let print_compile_error lxm msg = (
  Printf.eprintf "%s\n" (compile_error_string lxm msg);
  flush stderr
)

let print_runtime_error lxm msg = (
  Printf.eprintf "%s\n" (compile_error_string lxm msg);
  flush stderr
)

(** ---------------------------------------------------------------------
Warning (associ� � un lexeme) sur stderr
----------------------------------------------------------------------*)
let warning lxm msg = (
  Printf.eprintf  "Warning. %s:\n---> %s\n" (Lxm.details lxm) msg;
  flush stderr
)

(** ---------------------------------------------------------------------
Message d'erreur (sans lexeme) sur stderr
----------------------------------------------------------------------*)
let print_global_error msg = (
   Printf.eprintf "Error: %s\n" msg ;
	flush stderr
)

(**---------------------------------------------------------------------
Message d'erreur interne (avec fonction) sur stderr
----------------------------------------------------------------------*)
let print_internal_error fnme msg = (
   Printf.eprintf "Sorry, Internal Error. function %s:\n---> %s\n" fnme msg ;
	flush stderr
)
