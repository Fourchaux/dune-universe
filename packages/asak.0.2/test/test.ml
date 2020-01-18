(* This file is part of asak.
 *
 * Copyright (C) 2019 IRIF / OCaml Software Foundation.
 *
 * asak is distributed under the terms of the MIT license. See the
 * included LICENSE file for details. *)

open Asak

let threshold = Lambda_hash.Hard 0

let rec last x xs =
  match xs with
  | [] -> x
  | x::xs -> last x xs

let get_last_lambda_of_str str =
  match Parse_structure.read_string str with
  | [] -> failwith "empty"
  | x::xs ->
     let (_,lst) = last x xs in
     lst

let testable_hash =
  let open Alcotest in
  let hash = pair int string in
  pair hash (slist hash compare)

let hash_and_compare name hash str1 str2 () =
  let lambda1 = get_last_lambda_of_str str1 in
  let lambda2 = get_last_lambda_of_str str2 in
  let open Alcotest in
  check testable_hash name (hash lambda1) (hash lambda2)

let hash_strict =
  Lambda_hash.(hash_lambda {should_sort=false;hash_var=true} threshold)

let tests_same_hash =
  [("alpha-conv1", ( "let f a b = a + b"
                   , "let f x y = x + y" ));

   ("alpha-conv2", ( "let f a = let b = a in a + b"
                   , "let f a = let x = a in a + x" ));

   ("open"       , ( "let f g = let open List in map g"
                   , "let f g = List.map g" ));

   ("match-order", ( "let f x = match x with | Some x -> x | None -> 1"
                   , "let f x = match x with | None -> 1 | Some x -> x"));

#if OCAML_VERSION >= (4, 08, 0)

  ("inline"      , ( "let f x = let a x = x in a x"
                   , "let f x = x" ));

   ("inline2"    , ( "let f = let a = 2 in a"
                   , "let f = 2" ));

   ("function"   , ( "let f x = match x with | Some x -> x | None -> 1"
                   , "let f = function | Some x -> x | None -> 1"));

#endif
  ]

let same_hash =
  let run_test (name, (str1, str2)) =
    Alcotest.test_case name `Quick @@
      hash_and_compare "same_hash" hash_strict str1 str2 in
  List.map run_test tests_same_hash

let () =
  let open Alcotest in
  run "asak" [
      "same hash", same_hash;
    ]
