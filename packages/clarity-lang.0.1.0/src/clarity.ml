(* This is free and unencumbered software released into the public domain. *)

#include "integer.ml"
#include "grammar.ml"

let int_literal z = IntLiteral (Integer.of_int z)
let uint_literal n = UintLiteral (Integer.of_int n)

#include "compare.ml"
#include "print.ml"
#include "sexp.ml"
#include "library.ml"

#include "parser.ml"
#include "lexer.ml"

#include "parse.ml"
