include Soupault_common

(** Reads a file and return its content *)
let get_file_content file =
  try Ok (Soup.read_file file)
  with Sys_error msg -> Error msg

(* Result wrapper for FileUtil.cp *)
let cp fs d =
  try
    let () = FileUtil.mkdir ~parent:true d in
    Ok (FileUtil.cp fs d)
  with
  | FileUtil.CpError msg -> Error msg
  | FileUtil.MkdirError msg -> Error msg

(** Exception-safe list tail function that assumes that empty list's
    tail is an empty list. *)
let safe_tl xs =
    match xs with
    | [] -> []
    | _ :: xs' -> xs'

(** Removes the last element of a list *)
let drop_tail xs = List.rev xs |> safe_tl |> List.rev

(** Removes the first element of a list *)
let drop_head xs = safe_tl xs

(** Shortcut for checking if a list has this element *)
let in_list xs x = List.exists ((=) x) xs

let any_in_list xs ys =
  List.fold_left (fun acc x -> (in_list ys x) || acc) false xs

(** Extracts keys from an assoc list *)
let assoc_keys xs = List.fold_left (fun acc (x, _) -> x :: acc) [] xs

let assoc_values xs = List.map (fun (_, v) -> v) xs

let assoc_map f kvs = List.map (fun (k, v) -> (k, f v)) kvs

(** Result-aware iteration *)
let rec iter ?(ignore_errors=false) ?(fmt=(fun x -> x)) f xs =
  match xs with
  | [] -> Ok ()
  | x :: xs ->
    let res = f x in
    begin
      match res with
      | Ok _ -> iter ~ignore_errors:ignore_errors ~fmt:fmt f xs
      | Error msg as e ->
        if ignore_errors then let () = Logs.warn @@ fun m -> m "%s" (fmt msg) in Ok ()
        else e
    end

(* Result-aware fold *)
let rec fold_left ?(ignore_errors=false) ?(fmt=(fun x -> x)) f acc xs =
  match xs with
  | [] -> Ok acc
  | x :: xs ->
    let acc' = f acc x in
    begin
      match acc' with
      | Ok acc' -> fold_left ~ignore_errors:ignore_errors ~fmt:fmt f acc' xs
      | Error msg as e ->
        if ignore_errors then
          let () = Logs.warn @@ fun m -> m "%s" (fmt msg) in
          fold_left ~ignore_errors:ignore_errors ~fmt:fmt f acc xs
        else e
    end

(** Just a convenience function for Re.matches *)
let get_matching_strings r s =
  try
    let re = Re.Perl.compile_pat r in
    Ok (Re.matches re s)
  with Re__Perl.Parse_error -> Error (Printf.sprintf "Failed to parse regex %s" r)

let regex_replace ?(all=false) s pat sub =
  try
    let re = Re.Perl.compile_pat pat in
    Re.replace ~all:all ~f:(fun _ -> sub) re s
  with Re__Perl.Parse_error | Re__Perl.Not_supported ->
    soupault_error @@ Printf.sprintf "Malformed regex \"%s\"" pat

(** Just prints a hardcoded program version *)
let print_version () =
  Printf.printf "soupault %s\n" Defaults.version_string;
  print_endline "Copyright 2021 Daniil Baturin";
  print_endline "Soupault is free software distributed under the MIT license";
  print_endline "Visit https://www.soupault.app/reference-manual for documentation"

(** Warns about a deprecated option *)
let deprecation_warning f opt msg config =
  let value = f opt config in
  match value with
  | None -> ()
  | Some _ -> Logs.warn @@ fun m -> m "Deprecated option %s: %s" opt msg

(* Makes a heading slug for the id attribute.
   In the "hard" mode it replaces everything but ASCII letters and digits with hyphens.
   In the "soft" mode it only replaces whitespace with hyphens.
   HTML standards only demand that id should not have whitespace in it,
   contrary to the popular opinion.
 *)
let slugify ?(lowercase=true) ?(regex=None) ?(sub=None) s =
  let regex = Option.value ~default:"[^a-zA-Z0-9\\-]" regex in
  let sub = Option.value ~default:"-" sub in
  let s = Re.replace ~all:true ~f:(fun _ -> sub) (Re.Perl.compile_pat regex) s in
  if lowercase then String.lowercase_ascii s else s

let profile_matches profile build_profiles =
  (* Processing steps should run unless they have a "profile" option
     and it doesn't match the current build profile. *)
  match profile, build_profiles with
  | None, _ -> true
  | Some _, [] -> false
  | Some p, _ -> Option.is_some @@ List.find_opt ((=) p) build_profiles

(* Fixup for FilePath.get_extension raising Not_found for files without extensions.

   See https://github.com/gildor478/ocaml-fileutils/issues/12 for details.
 *)
let get_extension file =
  try FilePath.get_extension file
  with Not_found -> ""

let get_extensions file =
  let parts = String.split_on_char '.' file in
  drop_head parts

let has_extension extension file =
  let extensions = get_extensions file in
  let res = List.find_opt ((=) extension) extensions in
  match res with
  | None -> false
  | Some _ -> true

(* Remove trailing slashes from a path. *)
let normalize_path path =
  (* If a path is empty, leave it empty.
     Right now soupault treats build_dir="" as
     "use the current working dir for build dir".
     Until we all decide whether it's a good idea or not,
     let's keep it an easily removable line.
   *)
  if path = "" then path else
  let path = Re.replace  ~f:(fun _ -> "") (Re.Perl.compile_pat "/$") path in
  if path = "" then "/" else path

let concat_path fs = List.fold_left FilePath.concat "" fs

let split_path p =
  let sep = if Sys.win32 then "(\\\\)+" else "(/)+" in
  Re.split (Re.Perl.compile_pat sep) p

let string_of_float f =
  if f = (Float.round f) then int_of_float f |> string_of_int
  else string_of_float f

(* Ezjsonm erroneously believes that JSON only allows arrays or objects at the top level.
   That hasn't been true for quite a while: bare numbers, strings etc. are valid JSON objects.
   This is a kludge for compensating for it.
 *)
let string_of_json_primitive j =
  match j with
  | `String s -> s
  | `Float f -> string_of_float f
  | `Bool b -> string_of_bool b
  | `Null -> "null"
  | _ -> failwith "Ezjsonm needs a fix for standards compliance"

let rec parse_date fmts date_string =
  match fmts with
  | [] ->
    let () = Logs.debug @@ fun m -> m "Field value \"%s\" could not be parsed as a date, interpreting as a string" date_string in
    None
  | f :: fs -> begin
    let parser = ODate.Unix.From.generate_parser f in
    match parser with
    | None -> soupault_error (Printf.sprintf "Date format \"%s\" is invalid." f)
    | Some parser ->
      try
        let date = ODate.Unix.From.string parser date_string in
        let () = Logs.debug @@ fun m -> m "Date string \"%s\" matched format \"%s\"" date_string f in
        Some date
      with _ -> parse_date fs date_string
  end

let format_date fmt date =
  let printer = ODate.Unix.To.generate_printer fmt in
  match printer with
  | None -> soupault_error (Printf.sprintf "Date format \"%s\" is invalid." fmt)
  | Some printer -> ODate.Unix.To.string printer date

(* TOML/JSON convertors *)
let rec toml_of_json j =
  let open Otoml in
  match j with
  | `Float n -> TomlFloat n
  | `Bool b -> TomlBoolean b
  | `String s -> TomlString s
  | `A js -> TomlArray (List.map toml_of_json js)
  | `O os -> TomlTable (List.map (fun (k, v) -> (k, toml_of_json v)) os)
  | `Null -> TomlTable []

let rec toml_to_json t =
  let open Otoml in
  match t with
  | TomlString s -> `String s
  | TomlInteger i -> `Float (float_of_int i)
  | TomlFloat f -> `Float f
  | TomlBoolean b -> `Bool b
  | TomlLocalTime s -> `String s
  | TomlLocalDate s -> `String s
  | TomlLocalDateTime s -> `String s
  | TomlOffsetDateTime s -> `String s
  | TomlArray xs | TomlTableArray xs -> `A (List.map toml_to_json xs)
  | TomlTable os | TomlInlineTable os -> `O (List.map (fun (k, v) -> (k, toml_to_json v)) os)
