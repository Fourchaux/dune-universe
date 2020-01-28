module License = License
module Utils = Utils

val run :
  project_kind:[ `Library | `Binary | `Executable ] ->
  (* These are asked for from Stdin if not supplied *)
  ?name:string ->
  ?project_synopsis:string ->
  ?maintainer_fullname:string ->
  ?maintainer_email:string ->
  ?github_organisation:string ->
  ?initial_version:string ->
  license:License.t ->
  dependencies:string list ->
  version_dune:string ->
  version_ocaml:string ->
  version_opam:string ->
  version_ocamlformat:string ->
  ocamlformat_options:(string * string) list ->
  dry_run:bool ->
  non_interactive:bool ->
  git_repo:bool ->
  ?current_year:int ->
  unit ->
  unit
