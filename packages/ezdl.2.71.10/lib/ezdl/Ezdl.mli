
(*-----------------------------------------------------------
Interface avec la libdl C standard (POSIX)
-------------------------------------------------------------
N.B. la seule libert�e prise est dans la gestion des erreurs :
les fonctions l�vent une exception Failure avec le r�sultat
de la fonction C "dlerror" (qui n'est donc pas fournie).
-----------------------------------------------------------*)
(* Le type "pointeur generique" void* est abstrait
   on fait quand m�me une difference entre le handler
   de la librairie (type t) et les handlers de symboles
   dans la librairie (type chandler)
*)
type t
type cfunc

(* stub pour les fonction c :
toutes terminent normalement ou l�vent Failure "explication"
 *)
val dlopen : string -> t
val dlsym : t -> string -> cfunc
val dlclose : t -> unit 

(*-----------------------------------------------------------
Utilitaires pour l'appel des fonctions des dl 
-------------------------------------------------------------
L'utilisation de lib. dyn. pose �videmment des probl�mes
de typages et de compatibilit� entre types caml et C.

Entiers :
---------
Les int natifs OCAML correspondent aux int/long C.
   - Il peut y avoir des probl�mes sur les architectures
   o� int et long ne sont pas les m�mes.
   - La perte d'un bit due au codage OCAML peut entrainer
   des probl�mes de d�bordement QUI NE SONT PAS PRIS EN COMPTE
   (e.g. 31 bits vs 32 bits).

Flottants :
----------
Les float OCAML correspondent aux double C (norme IEEE 64 bits)
   - Il n'y a pas de support pour les float C (flottants sur
   un mot machine, typiquement 32 bits).

Cha�nes de caract�res :
-----------------------
Les string OCAML correspondent aux "null terminated strings" de C,
(la valeur C est donc de type char*  ).
    - Attention � la gestion m�moire et au partage d'adresse !

Pointeurs g�n�riques :
----------------------
Le type abstrait cptr permet d'�changer des adresses 
provenant de C (n'importe quel type* ), en particulier
les t et cfunc de ce module se castent en cptr.

Appels de fonctions C externes :
--------------------------------
Cela pose un (gros) probl�me de typage dynamique,
au niveau de CAML, mais aussi au niveau du code "stub" C :
pour �tre certain que les arguments et les r�sultats sont
�chang�s correctement il faut que l'appel soit statiquement
bien typ� (le passage des param�tres change d'une architecture
� l'autre et il est donc impossible d'avoir un code 
g�n�rique correct). 
Pour faciliter la t�che, au moins du cot� OCAML, on fournit :
   - quelques "wrappeurs" pour les profils courants (code
   C relativement efficace).
   - un m�canisme g�n�ral bas� sur un type union (carg) pour
   les autres fonctions.
      * N.B. m�me dans ce cas, le type du r�sultat attendu
      DOIT �tre connu au niveau du wrappeur C, il y a donc
      autant de fonctions que de types de r�sultats.
      * N.B. on doit pr�voir un code C (wrappeur) pour TOUTES
      les formes possibles de profil : le nombre d'arguments
      est donc limit� � 5.
-----------------------------------------------------------*)
(* Type abstrait des adresses C :
   Mn�mo   CAML    C
      i -> int    (long)
      f -> float  (double)
      s -> string (char* sur NTS)
      p -> <abst> (type* pourt tout type)
		u -> void
*)
(* n'importe quel pointeur externe peut se caster en cptr *)
type cptr

val cptr_of : 'a -> cptr

(* Quelques "profils" standards sont fournis *)
val f2f : cfunc -> float -> float
val ff2f : cfunc -> float -> float -> float

val i2i : cfunc -> int -> int
val ii2i : cfunc -> int -> int -> int
val iii2i : cfunc -> int -> int -> int -> int

(* pour les autres profils, les arguments sont pass� dans une liste *)
type carg =
    Int_carg of int
  | Double_carg of float 
  | String_carg of string 
  | Ptr_carg of cptr 
	  
val carg_to_string : carg -> string

type cargs = carg list

(* mais il faut quand m�me sp�cifier le type du r�sultat attendu ! *)

val cargs2i : cfunc -> cargs -> int 
val cargs2f : cfunc -> cargs -> float 
val cargs2s : cfunc -> cargs -> string 


