open Base
open Stdio
module C = Configurator.V1

let write_sexp fn sexp =
  Out_channel.write_all fn ~data:(Sexp.to_string sexp)

let () =
  C.main ~name:"OCaml_R" (fun c ->
      let default : C.Pkg_config.package_conf =
        { libs   = ["-lR"] ; cflags = [] }
      in
      let conf =
        match C.Pkg_config.get c with
        | None -> default
        | Some pc ->
          Option.value (C.Pkg_config.query pc ~package:"libR libRmath") ~default
      in
      write_sexp "c_flags.sexp"         (sexp_of_string (String.concat ~sep:" " conf.cflags)) ;
      write_sexp "c_library_flags.sexp" (sexp_of_string (String.concat ~sep:" " conf.libs))
    )
