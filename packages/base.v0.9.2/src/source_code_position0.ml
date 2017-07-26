open! Import

module T = struct
  type t = Caml.Lexing.position =
    { pos_fname : string;
      pos_lnum : int;
      pos_bol : int;
      pos_cnum : int;
    }
  [@@deriving_inline compare, hash, sexp]
  let t_of_sexp : Sexplib.Sexp.t -> t =
    let _tp_loc = "src/source_code_position0.ml.T.t"  in
    function
    | Sexplib.Sexp.List field_sexps as sexp ->
      let pos_fname_field = ref None

      and pos_lnum_field = ref None

      and pos_bol_field = ref None

      and pos_cnum_field = ref None

      and duplicates = ref []

      and extra = ref []
      in
      let rec iter =
        function
        | (Sexplib.Sexp.List ((Sexplib.Sexp.Atom
                                 field_name)::_field_sexp::[]))::tail ->
          ((match field_name with
             | "pos_fname" ->
               (match !pos_fname_field with
                | None  ->
                  let fvalue = string_of_sexp _field_sexp  in
                  pos_fname_field := (Some fvalue)
                | Some _ -> duplicates := (field_name :: (!duplicates)))
             | "pos_lnum" ->
               (match !pos_lnum_field with
                | None  ->
                  let fvalue = int_of_sexp _field_sexp  in
                  pos_lnum_field := (Some fvalue)
                | Some _ -> duplicates := (field_name :: (!duplicates)))
             | "pos_bol" ->
               (match !pos_bol_field with
                | None  ->
                  let fvalue = int_of_sexp _field_sexp  in
                  pos_bol_field := (Some fvalue)
                | Some _ -> duplicates := (field_name :: (!duplicates)))
             | "pos_cnum" ->
               (match !pos_cnum_field with
                | None  ->
                  let fvalue = int_of_sexp _field_sexp  in
                  pos_cnum_field := (Some fvalue)
                | Some _ -> duplicates := (field_name :: (!duplicates)))
             | _ ->
               if !Sexplib.Conv.record_check_extra_fields
               then extra := (field_name :: (!extra))
               else ());
           iter tail)
        | (Sexplib.Sexp.List ((Sexplib.Sexp.Atom field_name)::[]))::tail ->
          ((let _ = field_name  in
            if !Sexplib.Conv.record_check_extra_fields
            then extra := (field_name :: (!extra))
            else ());
           iter tail)
        | (Sexplib.Sexp.Atom _|Sexplib.Sexp.List _ as sexp)::_ ->
          Sexplib.Conv_error.record_only_pairs_expected _tp_loc sexp
        | [] -> ()  in
      (iter field_sexps;
       (match !duplicates with
        | _::_ ->
          Sexplib.Conv_error.record_duplicate_fields _tp_loc (!duplicates)
            sexp
        | [] ->
          (match !extra with
           | _::_ ->
             Sexplib.Conv_error.record_extra_fields _tp_loc (!extra) sexp
           | [] ->
             (match ((!pos_fname_field), (!pos_lnum_field),
                     (!pos_bol_field), (!pos_cnum_field))
              with
              | (Some pos_fname_value,Some pos_lnum_value,Some
                                                            pos_bol_value,Some pos_cnum_value) ->
                {
                  pos_fname = pos_fname_value;
                  pos_lnum = pos_lnum_value;
                  pos_bol = pos_bol_value;
                  pos_cnum = pos_cnum_value
                }
              | _ ->
                Sexplib.Conv_error.record_undefined_elements _tp_loc
                  sexp
                  [((Sexplib.Conv.(=) (!pos_fname_field) None),
                    "pos_fname");
                   ((Sexplib.Conv.(=) (!pos_lnum_field) None),
                    "pos_lnum");
                   ((Sexplib.Conv.(=) (!pos_bol_field) None), "pos_bol");
                   ((Sexplib.Conv.(=) (!pos_cnum_field) None),
                    "pos_cnum")]))))
    | Sexplib.Sexp.Atom _ as sexp ->
      Sexplib.Conv_error.record_list_instead_atom _tp_loc sexp

  let sexp_of_t : t -> Sexplib.Sexp.t =
    function
    | { pos_fname = v_pos_fname; pos_lnum = v_pos_lnum; pos_bol = v_pos_bol;
        pos_cnum = v_pos_cnum } ->
      let bnds = []  in
      let arg = sexp_of_int v_pos_cnum  in
      let bnd = Sexplib.Sexp.List [Sexplib.Sexp.Atom "pos_cnum"; arg]  in
      let bnds = bnd :: bnds  in
      let arg = sexp_of_int v_pos_bol  in
      let bnd = Sexplib.Sexp.List [Sexplib.Sexp.Atom "pos_bol"; arg]  in
      let bnds = bnd :: bnds  in
      let arg = sexp_of_int v_pos_lnum  in
      let bnd = Sexplib.Sexp.List [Sexplib.Sexp.Atom "pos_lnum"; arg]  in
      let bnds = bnd :: bnds  in
      let arg = sexp_of_string v_pos_fname  in
      let bnd = Sexplib.Sexp.List [Sexplib.Sexp.Atom "pos_fname"; arg]  in
      let bnds = bnd :: bnds  in Sexplib.Sexp.List bnds

  let (hash_fold_t :
         Ppx_hash_lib.Std.Hash.state -> t -> Ppx_hash_lib.Std.Hash.state) =
    fun hsv  ->
    fun arg  ->
      hash_fold_int
        (hash_fold_int
           (hash_fold_int (hash_fold_string hsv arg.pos_fname) arg.pos_lnum)
           arg.pos_bol) arg.pos_cnum

  let (hash : t -> Ppx_hash_lib.Std.Hash.hash_value) =
    fun arg  ->
      Ppx_hash_lib.Std.Hash.get_hash_value
        (hash_fold_t (Ppx_hash_lib.Std.Hash.create ()) arg)

  let compare : t -> t -> int =
    fun a__001_  ->
    fun b__002_  ->
      if Ppx_compare_lib.phys_equal a__001_ b__002_
      then 0
      else
        (match compare_string a__001_.pos_fname b__002_.pos_fname with
         | 0 ->
           (match compare_int a__001_.pos_lnum b__002_.pos_lnum with
            | 0 ->
              (match compare_int a__001_.pos_bol b__002_.pos_bol with
               | 0 -> compare_int a__001_.pos_cnum b__002_.pos_cnum
               | n -> n)
            | n -> n)
         | n -> n)

  [@@@end]
end

include T
include Comparator.Make(T)

(* This is the same function as Ppx_here.lift_position_as_string. *)
let make_location_string ~pos_fname ~pos_lnum ~pos_cnum ~pos_bol =
  String0.concat
    [ pos_fname
    ; ":"; string_of_int pos_lnum
    ; ":"; string_of_int (pos_cnum - pos_bol)
    ]

let to_string {Caml.Lexing.pos_fname; pos_lnum; pos_cnum; pos_bol} =
  make_location_string ~pos_fname ~pos_lnum ~pos_cnum ~pos_bol

let sexp_of_t t = Sexp.Atom (to_string t)
