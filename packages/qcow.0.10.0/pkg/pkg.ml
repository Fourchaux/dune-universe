#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let () =
  Pkg.describe "qcow" @@ fun c ->
  Ok [ Pkg.mllib "lib/qcow.mllib";
       Pkg.bin "cli/main" ~dst:"qcow-tool";
       Pkg.test "lib_test/test" ~args:Cmd.(v "-runner" % "sequential");
       Pkg.test "lib_test/compact_random";
       Pkg.test "lib_test/compact_random" ~args:Cmd.(v "-compact-mid-write" % "-stop-after" % "16");
  ]
