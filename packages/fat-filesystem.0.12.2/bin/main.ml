(*
 * Copyright (C) 2011-2013 Citrix Systems Inc
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

let project_url = "http://github.com/mirage/ocaml-fat"

open Cmdliner

(* Help sections common to all commands *)

let _common_options = "COMMON OPTIONS"
let help = [
  `S _common_options;
  `P "These options are common to all commands.";
  `S "MORE HELP";
  `P "Use `$(mname) $(i,COMMAND) --help' for help on a single command."; `Noblank;
  `S "BUGS"; `P (Printf.sprintf "Check bug reports at %s" project_url);
]

(* Options common to all commands *)
let common_options_t =
  let docs = _common_options in
  let debug =
    let doc = "Give only debug output." in
    Arg.(value & flag & info ["debug"] ~docs ~doc) in
  let verb =
    let doc = "Give verbose output." in
    let verbose = true, Arg.info ["v"; "verbose"] ~docs ~doc in
    Arg.(last & vflag_all [false] [verbose]) in
  let unbuffered =
    let doc = "Use unbuffered I/O (via O_DIRECT)." in
    Arg.(value & flag & info ["unbuffered"] ~docs ~doc) in
  Term.(pure Common.make $ debug $ verb $ unbuffered)

let filename =
  let doc = Printf.sprintf "Path to the FAT image file." in
  Arg.(value & pos 0 file "fat.img" & info [] ~doc)

let path =
  let doc = Printf.sprintf "Path within the FAT image file." in
  Arg.(value & pos 1 string "" & info [] ~doc)

let create_cmd =
  let doc = "create an empty FAT image" in
  let man = [
    `S "DESCRIPTION";
    `P "Create an empty FAT filesystem";
  ] @ help in
  (* can't use 'file' because it won't exist yet *)
  let filename =
    let doc = Printf.sprintf "Path to the FAT image file." in
    Arg.(value & pos 0 string "fat.img" & info [] ~doc) in
  let size =
    let doc = "Size of the image" in
    Arg.(value & pos 1 string "16MiB" & info [] ~doc) in
  Term.(ret(pure Impl.create $ common_options_t $ filename $ size)),
  Term.info "create" ~sdocs:_common_options ~doc ~man

let add_cmd =
  let doc = "add files to a FAT image" in
  let man = [
    `S "DESCRIPTION";
    `P "Add a set of files to a FAT filesystem image."
  ] @ help in
  let files = Arg.(non_empty & pos_all file [] & info [] ~docv:"FILE") in
  Term.(ret(pure Impl.add $ common_options_t $ filename $ files)),
  Term.info "add" ~sdocs:_common_options ~doc ~man

let list_cmd =
  let doc = "list files in a FAT image" in
  let man = [
    `S "DESCRIPTION";
    `P "List the set of files contained within a FAT filesystem image."
  ] @ help in
  Term.(ret(pure Impl.list $ common_options_t $ filename)),
  Term.info "list" ~sdocs:_common_options ~doc ~man

let cat_cmd =
  let doc = "extract a single file from a FAT image" in
  let man = [
    `S "DESCRIPTION";
    `P "extract a single file from a FAT filesystem image."
  ] @ help in
  Term.(ret(pure Impl.cat $ common_options_t $ filename $ path)),
  Term.info "cat" ~sdocs:_common_options ~doc ~man

let default_cmd =
  let doc = "manipulate FAT filesystem images" in
  let man = help in
  Term.(ret (pure (fun _ -> `Help (`Pager, None)) $ common_options_t)),
  Term.info "fat" ~version:"1.0.0" ~sdocs:_common_options ~doc ~man

let cmds = [create_cmd; add_cmd; list_cmd; cat_cmd]

let _ =
  match Term.eval_choice default_cmd cmds with
  | `Error _ -> exit 1
  | _ -> exit 0
