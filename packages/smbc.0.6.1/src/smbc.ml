
(* This file is free software. See file "license" for more details. *)

type config = {
  syntax: Ast.syntax;
  max_depth: int;
  print_stat: bool;
  dot_term_graph: string option;
  pp_hashcons: bool;
  progress : bool;
  dimacs: string option;
  deepening_step: int option;
  uniform_depth: bool;
  quant_depth : int;
  eval_under_quant: bool;
  check: bool;
  check_proof: bool;
}

let parse_file (syn:Ast.syntax) (file:string) : Ast.statement list Ast.or_error =
  Log.debugf 2 (fun k->k "(@[parse_file@ %S@])" file);
  let dir = Filename.dirname file in
  Ast.parse ~include_dir:dir ~file syn

let parse syn input: Ast.statement list =
  let res = match input with
    | `None -> failwith "provide one file or use --stdin"
    | `Stdin -> Ast.parse_stdin syn
    | `File f -> parse_file syn f
  in
  match res with
    | Result.Error msg -> print_endline msg; exit 1
    | Result.Ok l -> l

let solve ~config (ast:Ast.statement list) : unit =
  let module Conf = struct
    let max_depth = config.max_depth
    let pp_hashcons = config.pp_hashcons
    let progress = config.progress
    let deepening_step = config.deepening_step
    let uniform_depth = config.uniform_depth
    let dimacs_file = config.dimacs
    let quant_unfold_depth = config.quant_depth
    let check_proof = config.check_proof
    let eval_under_quant = config.eval_under_quant
  end in
  let module S = Solver.Make(Conf)(struct end) in
  let on_exit = [] in
  (* solve *)
  S.add_statement_l ast;
  let res = S.solve ~on_exit ~check:config.check () in
  let is_prove = S.is_prove() in
  if config.print_stat then Format.printf "%a@." S.pp_stats ();
  match res with
  | S.Sat m ->
    if is_prove then (
      Format.printf "\r(@[<1>result @{<Yellow>COUNTERSAT@}@ :model @[%a@]@])@."
        (Model.pp_syn config.syntax) m;
    ) else (
      Format.printf "\r(@[<1>result @{<Green>SAT@}@ :model @[%a@]@])@."
        (Model.pp_syn config.syntax) m;
    )
  | S.Unsat ->
    if is_prove then (
      Format.printf "\r(result @{<Green>THEOREM@})@."
    ) else (
      Format.printf "\r(result @{<Yellow>UNSAT@})@."
    )
  | S.Unknown u  ->
    Format.printf "\r(result @{<blue>UNKNOWN@} :reason %a)@." S.pp_unknown u

(** {2 Main} *)

let print_input_ = ref false
let color_ = ref true
let dot_term_graph_ = ref ""
let stats_ = ref false
let progress_  = ref false
let pp_hashcons_ = ref false
let max_depth_ = ref 1000
let depth_step_ = ref 1
let check_ = ref false
let timeout_ = ref ~-1
let syntax_ = ref Ast.Auto
let uniform_depth_ = ref false
let quant_depth_ = ref 3
let eval_under_quant_ = ref true
let version_ = ref false
let dimacs_ = ref "" (* file to put sat problem in *)
let check_proof_ = ref false

let file = ref `None

let set_file s = match !file with
  | `None -> file := `File s
  | `Stdin -> raise (Arg.Bad "cannot combine --stdin and file")
  | `File _ -> raise (Arg.Bad "provide at most one file")

let set_stdin () = match !file with
  | `Stdin -> ()
  | `None -> file := `Stdin; syntax_ := Ast.Tip
  | `File _ -> raise (Arg.Bad "cannot combine --stdin and file")

let set_syntax_ s =
  syntax_ :=
    begin match CCString.uncapitalize_ascii s with
      | "tip" -> Ast.Tip
      | _ -> failwith ("unknown syntax " ^ s) (* TODO list *)
    end

let set_debug_ d =
  Log.set_debug d;
  Msat.Log.set_debug d;
  ()

let options =
  Arg.align [
    "--print-input", Arg.Set print_input_, " print input";
    "--max-depth", Arg.Set_int max_depth_, " set max depth";
    "--dot-term-graph", Arg.Set_string dot_term_graph_, " print term graph in file";
    "--check", Arg.Set check_, " check model";
    "--no-check", Arg.Clear check_, " do not check model";
    "-nc", Arg.Clear color_, " do not use colors";
    "-p", Arg.Set progress_, " progress bar";
    "--input", Arg.String set_syntax_, " input format";
    "--stdin", Arg.Unit set_stdin, " parse on stdin (forces --input tip)";
    "-i", Arg.String set_syntax_, " alias to --input";
    "--pp-hashcons", Arg.Set pp_hashcons_, " print hashconsing IDs";
    "--debug", Arg.Int set_debug_, " set debug level";
    "-d", Arg.Int set_debug_, " set debug level";
    "--stats", Arg.Set stats_, " print stats";
    "--backtrace", Arg.Unit (fun () -> Printexc.record_backtrace true), " enable backtrace";
    "--depth-step", Arg.Set_int depth_step_, " increment for iterative deepening";
    "--uniform-depth", Arg.Set uniform_depth_, " uniform depth";
    "--no-uniform-depth", Arg.Clear uniform_depth_, " non-uniform depth";
    "--quant-depth", Arg.Set_int quant_depth_, " unfolding depth for quantifiers";
    "--timeout", Arg.Set_int timeout_, " timeout (in s)";
    "--dimacs", Arg.Set_string dimacs_, " file to output dimacs problem into";
    "--check-proof", Arg.Set check_proof_, " check propositional proofs";
    "--no-check-proof", Arg.Clear check_proof_, " do not check propositional proofs";
    "--eval-under-quant", Arg.Set eval_under_quant_, " evaluate under quantifiers";
    "--no-eval-under-quant", Arg.Clear eval_under_quant_, " evaluate under quantifiers";
    "-t", Arg.Set_int timeout_, " alias to --timeout";
    "--version", Arg.Set version_, " display version info";
  ]

let setup_timeout_ t =
  assert (t >= 1);
  Sys.set_signal Sys.sigalrm
    (Sys.Signal_handle (fun _ -> print_endline "(TIMEOUT)"; exit 0));
  ignore (Unix.alarm !timeout_);
  ()

let setup_gc () =
  let g = Gc.get () in
  g.Gc.space_overhead <- 3_000; (* major gc *)
  g.Gc.max_overhead <- 10_000; (* compaction *)
  g.Gc.minor_heap_size <- 500_000; (* ×8 to obtain bytes on 64 bits -->  *)
  Gc.set g

let () =
  Arg.parse options set_file
    "experimental SMT solver for datatypes and recursive functions.\n\
    \n\
    Usage: smbc [options] (file | --stdin).\n";
  CCFormat.set_color_default !color_;
  if !version_ then (
    Format.printf "version: %s@." Const.version;
    exit 0;
  );
  if !timeout_ >= 1 then setup_timeout_ !timeout_;
  setup_gc ();
  (* parse *)
  let ast = parse !syntax_ !file in
  if !print_input_
  then
    Format.printf "@[parsed:@ @[<v>%a@]@]@."
      CCFormat.(list ~sep:(return "@,") Ast.pp_statement) ast;
  (* solve *)
  let config = {
    max_depth = !max_depth_;
    syntax= !syntax_;
    print_stat = !stats_;
    progress = !progress_;
    pp_hashcons = !pp_hashcons_;
    quant_depth= !quant_depth_;
    eval_under_quant= !eval_under_quant_;
    uniform_depth = !uniform_depth_;
    dimacs = (if !dimacs_ = "" then None else Some !dimacs_);
    deepening_step =
      (if !depth_step_ = 0 then None else Some !depth_step_);
    dot_term_graph =
      (if !dot_term_graph_ = "" then None else Some !dot_term_graph_);
    check= !check_;
    check_proof= !check_proof_;
  } in
  solve ~config ast
