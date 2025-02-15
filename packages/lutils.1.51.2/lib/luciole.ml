(* Time-stamp: <modified the 23/07/2020 (at 11:35) by Erwan Jahier> *)
(*-----------------------------------------------------------------------
** This file may only be copied under the terms of the CeCill
** Public License
**-----------------------------------------------------------------------
**
** File: luciole.ml
** Author: erwan.jahier@univ-grenoble-alpes.fr
**
*)

(* Var name and C type *)
type vn_ct = string * string  

(** Generates stub files for calling luciole.  *)

(** Generate a Makefile that compiles files generated by gen_stubs,
   and calls luciole on the resulting .dro file.

   the first arg is a just a string used to invent file names
*)
let (_gen_makefile :string -> unit) =
  fun str -> 
  let oc = open_out ("Makefile." ^ str) in
  let p s = output_string oc s in
  let pn s = p (s^"\n") in
    
    p (Mypervasives.entete "# " LutilsVersion.str LutilsVersion.sha);
(*     pn "LURETTE_PATH=/home/jahier/lurette/"; *)
    pn "CFLAGS = -L$(LURETTE_PATH)/lib -I$(LURETTE_PATH)/include  -I$(LUSTRE_INSTALL)/include ";
    pn "";
    pn "LIBS = -lluc4c_nc -llucky_nc -lgmp -lm -ldl";
    pn "";
    pn ("all: " ^ str ^ ".dro");
    pn ("	simec ./" ^ str ^ ".dro");
    pn "";
(*     pn (str ^ ".c:" ^ str ^ "_luciole.c"); *)
(*     pn ""; *)
(*     pn (str ^ "_luciole.c: " ^ str ^ env_ext); *)
(*     pn ("	$(LURETTE_PATH)/bin/luc2c -pp lucky_cpp --luciole " ^ str ^ env_ext); *)
    pn "";
    pn (str ^ ".dro: " ^ str ^ "_luciole.o " ^ str ^ ".o");
    pn ("	g++ $(CFLAGS) " ^ str ^ "_luciole.o  " ^ str ^ ".o $(LIBS) -shared -o " ^ str ^ ".dro");
    pn "";
    pn "";
    pn "%.o: %.c";
    pn "	$(CC) $(CFLAGS) -c  $<";
    pn "";
    pn "";
    pn "clean:";
    pn ("	rm -f  "^str^".o "^str^".c  "^str^".h "^str^"_luciole.c  "
	^str^"_luciole.o  "^str^".dro  "^str^".h Makefile."^str);
    print_string ("File Makefile." ^ str ^ " has been created. Launch \n");
    print_string ("              make -f Makefile." ^ str ^ "\n to run luciole\n");
    close_out oc;
    ignore (Mypervasives.my_create_process "make" ["-f";("Makefile." ^ str)])

  
(* exported  *)
let (gen_stubs : ?boot: bool -> string -> vn_ct list -> vn_ct list -> unit) =
  fun ?(boot=true) str inputs outputs ->
  let oc = open_out (str^"_luciole.c") in
  let p s = output_string oc s in
  let pn s = p (s^"\n") in

  let d2r = function
    | "_real" | "real" | "float"  | "double" -> "real"
    | "_bool" | "bool" -> "bool"
    | "_int" -> "int"
    | _e -> "int"
  in
  let vn_ct_to_array (vn, ct) =
    pn ("   {\""^vn^"\", \""^(d2r ct)^"\", NULL},")
  in 
  let _vn_ct_to_output_functions i (vn,ct) =
    pn ("void "^str^"_O_"^vn^"("^str^"_ctx* cdata, "^
	(ct)^" val){");
    pn ("     _THIS->_"^vn^" = val;");
    pn "}";
    (i+1)
  in

  let vn_ct_to_input_init i (vn,_ct) =
    pn ("  _intab["^(string_of_int i)^"].valptr = (void*)(& _THIS->_"^vn^");");
    (i+1)
  in
  let vn_ct_to_output_init i (vn,_ct) =
    pn ("  _outab["^(string_of_int i)^"].valptr = (void*)(& _THIS->_"^vn^");");
    (i+1)
  in
  let simec_version_number = "1.1" in

  p (Mypervasives.entete "// " LutilsVersion.str LutilsVersion.sha);
  pn "/* droconf.h begins */
/*
Struct necessary for building a DRO archive
(Dynamically linkable Reactive Object)
Such an archive can be loaded by simec/luciole
*/
#define DROVERSION \"1.1\"
#define xstr(s) str(s)  /* converts macro to string */
#define str(s) #s
/* should be of type type dro_desc_t */
#define DRO_DESC_NAME  dro_desc
struct dro_var_t {
const char* ident;
const char* type;
void* valptr;
};

struct dro_desc_t {
const char* version;
const char* name;
int nbins;
struct dro_var_t* intab;
int nbouts;
struct dro_var_t* outab;
int ( *step )();
void ( *reset )();
void ( *init )();
}; 
/* droconf.h ends */
";
  pn "#include \"stdlib.h\"";      
  pn "#include <stdio.h>";
  pn "#include <string.h>";

  pn "typedef int _bool;";
  pn "typedef int _int;";
  pn "typedef double _real;";
  pn "struct _luciole_ctx {";
  pn "// INPUTS";
  List.iter 
    (fun (vn,t) -> pn ("    _"^ t ^ " _" ^ vn ^";"))
    inputs;
  pn "// OUTPUTS";
  List.iter
    (fun (vn,t) -> pn ("    _"^ t ^ " _" ^ vn ^";"))
    outputs;
  pn "};";
  pn "typedef struct _luciole_ctx luciole_ctx;";
  pn "static luciole_ctx* _THIS = NULL;";

  pn "// inputs array";
  pn "struct dro_var_t _intab[] = {";
  List.iter vn_ct_to_array inputs;
  pn "}; ";
  pn "";
  pn "// outputs array ";
  pn "struct dro_var_t _outab[] = {";
  List.iter vn_ct_to_array outputs;
  pn "};";
  pn "";

  pn "void __do_reset();";
  pn "void __do_init();";

  pn "
#define LINEMAXSIZE 256
void _read_pragma(char b[LINEMAXSIZE]) {
   int s = 1;

   if (!strcmp(b,\"#quit\")) exit(0);
   if (!strcmp(b,\"#q\")) exit(0);
   if (!strcmp(b,\"#reset\")) __do_reset();
   return;
}

/* Standard Input procedures **************/
_bool _get_bool(){
   char b[LINEMAXSIZE];
   _bool r = 0;
   int s = 1;
   char c;
   do {
      if(scanf(\"%s\", b)==EOF) exit(0);
      s = sscanf(b, \"%c\", &c);
      r = -1;
      if(c == 'q') exit(0);
      if(c == '#') _read_pragma(b);
      if((c == '0') || (c == 'f') || (c == 'F')) r = 0;
      if((c == '1') || (c == 't') || (c == 'T')) r = 1;
   } while((s != 1) || (r == -1));
   return r;
}
_int _get_int(){
   char b[LINEMAXSIZE];
   _int r;
   int s = 1;
   char c;
   do {
      if(scanf(\"%s\", b)==EOF) exit(0);
      s = sscanf(b, \"%c\", &c);
      if(c == 'q') exit(0);
      if(c == '#') {
         _read_pragma(b);
      } else {
        s = sscanf(b, \"%d\", &r);
      }
   } while(s != 1);
   return r;
}
_real _get_real(){
   char b[LINEMAXSIZE];
   _real r;
   int s = 1;
   char c;
   do {
      if(scanf(\"%s\", b)==EOF) exit(0);
      s = sscanf(b, \"%c\", &c);
      if(c == 'q') exit(0);
      if(c == '#') {
         _read_pragma(b);
      } else {
         s = sscanf(b, \"%lf\", &r);
      }
   } while(s != 1);
   return r;
}
/* Standard Output procedures **************/
void _put_bool(_bool _V){
   printf(\"%s\\n\", (_V)? \"t\" : \"f\");
}
void _put_int(_int _V){
   printf(\"%d\\n\", _V);
}
void _put_real(_real _V){
   printf(\"%f\\n\", _V);
}
";
  pn "void __do_reset(){";
  pn "fprintf(stdout,\"#reset\\n\");";
  pn " fprintf(stderr,\"reseting !!!\\n\");";
  pn "fflush(stdout);";
  pn "  _THIS = malloc(sizeof(luciole_ctx));";
  ignore (List.fold_left vn_ct_to_input_init 0 inputs);
  ignore (List.fold_left vn_ct_to_output_init 0 outputs);
  pn "}";

  pn "void __do_init(){";
  pn "  //reset or create";
  pn "  if(_THIS) {";
  pn "    // nop";
  pn "  } else {";
  pn "    fprintf(stderr,\"initing !!!\\n\");";
  pn "    _THIS = malloc(sizeof(luciole_ctx));";
  ignore (List.fold_left vn_ct_to_input_init 0 inputs);
  ignore (List.fold_left vn_ct_to_output_init 0 outputs);
  if not boot then
    List.iter (fun (vn,vt) -> pn ("     _THIS->_" ^ vn ^ " = _get_"^vt^"();")) outputs; 
  pn "    }";
  pn "}";

  pn "int __do_step();";
  pn "int internal_step(){";
  pn "  return __do_step();";
  pn "}";
  pn "void internal_reset(){";
  pn "  return __do_reset();";
  pn "}";
  pn "void internal_init(){";
  pn "  return __do_init();";
  pn "}";

  pn "// ";
  pn "struct dro_desc_t DRO_DESC_NAME = {";
  pn ("   \""^simec_version_number^"\",");
  pn ("   \""^str^"\",");
  pn ("   "^(string_of_int (List.length inputs))^",");
  pn "   _intab,";
  pn ("   "^(string_of_int (List.length outputs))^",");
  pn "   _outab,";
  pn "   internal_step,";
  pn "   internal_reset,";
  pn "   internal_init";
  pn "};";
  pn "";
  pn "int __do_step(){";
  pn "if(_THIS) {";
  List.iter (fun (vn,vt) -> pn ("   _put_"^vt^"(_THIS->_" ^ vn ^");")) inputs;
  pn "   fflush(stdout);";
  List.iter (fun (vn,vt) -> pn ("   _THIS->_" ^ vn ^ " = _get_"^vt^"();")) outputs;
  pn "   //always happy...";
  pn "   return 0;";
  pn "  } else {";
  pn "    printf(\"initialisation problem\\n\");";
  pn "    return 2;";
  pn " }";
  pn "}";

  flush oc;
  close_out oc;
  print_string ("File " ^ str ^ "_luciole.c has been created\n");
  flush stdout
