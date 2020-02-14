(* Copied from Filename (stdlib) for pre-4.04 compatibility *)
let chop_extension name =
  let is_dir_sep s i =
    match Sys.os_type with
    | "Unix" -> s.[i] = '/'
    | "Win32" | "Cygwin" ->
        let c = s.[i] in
        c = '/' || c = '\\' || c = ':'
    | _ -> assert false
  in
  let rec search_dot i =
    if i < 0 || is_dir_sep name i then invalid_arg "Filename.chop_extension"
    else if name.[i] = '.' then String.sub name 0 i
    else search_dot (i - 1)
  in
  search_dot (String.length name - 1)

let global_stanza ~libraries filenames =
  let bases = List.map chop_extension filenames in
  let libraries = List.map (( ^ ) " ") libraries in
  let pp_sexp_list = Fmt.(list ~sep:(const string "\n   ")) in
  Fmt.pr
    {|(executables
 (names
   %a
 )
 (libraries alcotest%a)
 (modules
   %a
 )
)
|}
    (pp_sexp_list Fmt.string) bases
    Fmt.(list string)
    libraries (pp_sexp_list Fmt.string) bases

let example_rule_stanza ~expect_failure filename =
  let base = chop_extension filename in
  let expect_failure =
    if expect_failure then "../../expect_failure.exe " else ""
  in
  (* Run Alcotest to get *.actual, then pass through the strip_randomness
     sanitiser to get *.processed. *)
  Fmt.pr
    {|
(rule
 (target %s.actual)
 (action
  (with-outputs-to %%{target}
   (run %s%%{dep:%s.exe})
  )
 )
)

(rule
 (target %s.processed)
 (action
  (with-outputs-to %%{target}
   (run ../../strip_randomness.exe %%{dep:%s.actual})
  )
 )
)

|}
    base expect_failure base base base

let example_alias_stanza ~package filename =
  let base = chop_extension filename in
  Fmt.pr
    {|
(alias
 (name runtest)
 (package %s)
 (action
   (diff %s.expected %s.processed)
 )
)
|}
    package base base

let is_example filename = Filename.check_suffix filename ".ml"

let main package expect_failure libraries =
  Sys.readdir "."
  |> Array.to_list
  |> List.sort String.compare
  |> List.filter is_example
  |> function
  | [] -> () (* no tests to execute *)
  | tests ->
      global_stanza ~libraries tests;
      List.iter
        (fun test ->
          example_rule_stanza ~expect_failure test;
          example_alias_stanza ~package test)
        tests

open Cmdliner

let package =
  let doc =
    Arg.info ~doc:"Package with which to associate the executables"
      [ "package" ]
  in
  Arg.(required & opt (some string) None & doc)

let libraries =
  let doc =
    Arg.info ~doc:"Additional libraries to make available to the executable"
      [ "libraries" ]
  in
  Arg.(value & opt (list string) [] & doc)

let expect_failure =
  let doc =
    Arg.info ~doc:"Negate the return status of the tests" [ "expect-failure" ]
  in
  Arg.(value & flag doc)

let term =
  Term.
    ( const main $ package $ expect_failure $ libraries,
      info ~version:"1.0.1" "gen_dune_rules" )

let () = Term.(exit @@ eval term)
