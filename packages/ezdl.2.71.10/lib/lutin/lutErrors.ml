(** Annexe : gestion des erreurs/warning

------------------------------------------------------------------------
	description :

	Exceptions et formatage des messages d'erreur.

	La compilation peut �chouer sur des exceptions pr�d�finies :

	- Sys_error of string :
	-----------------------
	erreur syst�me (li�e aux fichiers)

	- Parse_error :
	---------------
	dans le yacc

	- Compile_error of Lexeme.t * string :
	--------------------------------------
	une erreur de compil qu'on peut "situer" dans le source gr�ce
	� un lexeme *

	- Global_error of string :
	--------------------------
	une erreur qui n'est pas sp�cialement li�e � un lexeme,
	(mais peut-�tre li�e � un noeud -> void checkNode) *

	- Compile_node_error of CompileData.node_key * Lexeme.t * string :
	------------------------------------------------------------------
	une erreur de compil li�e � un lexeme et � un noeud (en fait
	une instance de template) particulier * ** ***

	- Global_node_error of CompileData.node_key * string :
	------------------------------------------------------------------
	une erreur de compil non li�e � un lexeme particulier,
	mais dependant lev�e lors de la compilation d'un noeud * ** ***

	*** Pas d�fini ici (� cause des %@#&! problemes de compil s�par�e),

----------------------------------------------------------------------

----------------------------------------------------------------------*)
open Lexeme

(*---------------------------------------------------------------------
Une erreur associ�e � un lexeme dans le fichier source
----------------------------------------------------------------------*)
exception Compile_error of Lexeme.t * string

(*---------------------------------------------------------------------
Une erreur plus generale
----------------------------------------------------------------------*)
exception Global_error of string

(*---------------------------------------------------------------------
Une erreur qui n'aurrait pas du arriver (fonction, message)
----------------------------------------------------------------------*)
exception Internal_error of string * string


(*---------------------------------------------------------------------
Formatage standard des lexemes dans les messages d'erreur
----------------------------------------------------------------------*)
let lexeme_details lxm = (
   Printf.sprintf "'%s' \nFile \"%s\", line %d, char %d-%d"
      lxm.str lxm.file lxm.line lxm.cstart lxm.cend
)
let lexeme_line_col lxm = (
   Printf.sprintf "(line %d, char %d-%d)"
      lxm.line lxm.cstart lxm.cend
)

(*---------------------------------------------------------------------
Formatage standard des erreurs de compil
----------------------------------------------------------------------*)
let compile_error_string lxm msg = (
   Printf.sprintf "Error, %s:\n---> %s" (lexeme_details lxm) msg
)

(*---------------------------------------------------------------------
Message d'erreur (associ� � un lexeme) sur stderr
----------------------------------------------------------------------*)
let print_compile_error lxm msg = (
   Printf.eprintf "%s\n" (compile_error_string lxm msg);
	flush stderr
)

(*---------------------------------------------------------------------
Warning (associ� � un lexeme) sur stderr
----------------------------------------------------------------------*)
let warning src msg = (
	match src with
	Some lxm ->
   	Printf.eprintf  "Warning. %s:\n---> %s\n" (lexeme_details lxm) msg
	| None ->
   	Printf.eprintf  "Warning. :\n---> %s\n" msg
)

(*---------------------------------------------------------------------
Message d'erreur (sans lexeme) sur stderr
----------------------------------------------------------------------*)
let print_global_error msg = (
   Printf.eprintf "Error, %s\n" msg ;
	flush stderr
)

(*---------------------------------------------------------------------
Message d'erreur interne (avec fonction) sur stderr
----------------------------------------------------------------------*)
let print_internal_error fnme msg = (
   Printf.eprintf "Sorry, Internal Error, function %s:\n---> %s\n" fnme msg ;
	flush stderr
)
