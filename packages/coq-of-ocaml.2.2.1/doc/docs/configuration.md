---
id: configuration
title: Configuration
---

We present the configuration mechanism of coq-of-ocaml to define some global settings. We write the configuration in a file in the [JSON format](https://www.json.org/json-en.html). To run coq-of-ocaml with a configuration file, use the `-config` option:
```sh
coq-of-ocaml -config configuration.json ...
```

The general structure of a configuration file is an object of entry keys and values:
```sh
{
  "entry_1": value_1,
  ...,
  "entry_n": value_n
}
```
An example is:
```json
{
  "error_message_blacklist": [
    "Unbound module Tezos_protocol_alpha_functor"
  ],
  "monadic_operators": [
    ["Error_monad.op_gtgteq", "let="],
    ["Error_monad.op_gtgteqquestion", "let=?"],
    ["Error_monad.op_gtgtquestion", "let?"]
  ],
  "require": [
    ["Tezos_raw_protocol_alpha", "Tezos"]
  ],
  "variant_constructors": [
    ["Dir", "Context.Dir"],
    ["Key", "Context.Key"],
    ["Hex", "MBytes.Hex"]
  ],
  "without_positivity_checking": [
    "src/proto_alpha/lib_protocol/storage_description.ml"
  ]
}
```
The configuration entries are described as follows.

## alias_barrier_modules
#### Example
```
"alias_barrier_modules": [
  "Tezos_protocol_environment_alpha__Environment"
]
```

#### Value
A list of module names at which to stop when iterating through record aliases to find the initial record definition.

#### Explanation
An example of OCaml code with a record alias is:
```ocaml
module A = struct
  type t = {a : string; b : bool}
end

module B = struct
  type t = A.t = {a : string; b : bool}
end

let x = {B.a = "hi"; b = true}
```
which generates:
```coq
Module A.
  Module t.
    Record record : Set := Build {
      a : string;
      b : bool }.
    Definition with_a a (r : record) :=
      Build a r.(b).
    Definition with_b b (r : record) :=
      Build r.(a) b.
  End t.
  Definition t := t.record.
End A.

Module B.
  Definition t : Set := A.t.
End B.

Definition x : B.t := {| A.t.a := "hi"; A.t.b := true |}.
```
Even if in OCaml we can talk about the field `B.a`, in Coq we transform it to `A.t.a` so that there is a single record definition. To do this transformation, we go through the record aliases up to the alias barriers, if any.

## constructor_map
#### Example
```
"constructor_map": [
  ["public_key_hash", "Ed25519", "Ed25519Hash"],
  ["public_key_hash", "P256", "P256Hash"],
  ["public_key_hash", "Secp256k1", "Secp256k1Hash"]
]
```

#### Value
A list of triples with a type name, a constructor name and a new constructor name to rename to. The type name must be the type name associated to the constructor, and is not prefixed by a module name. This type name is mostly there to help to disambiguate.

#### Explanation
In OCaml we can have different types with the same constructor names, as long as the OCaml compiler can differentiate them based on type information. In Coq this is not the case. The definition of two constructors with the same name generates a name collision. For this reason, we can selectively rename some constructors in coq-of-ocaml in order to avoid name collisions in Coq.

## error_category_blacklist
#### Example
```
"error_category_blacklist": [
  "extensible_type",
  "module",
  "side_effect"
]
```

#### Value
A list of error categories to black-list. The category of an error message is given in its header. For example:
```
--- foo.ml:1:1 ------------------------------------------- side_effect (1/1) ---

> 1 | let () =
> 2 |   print_endline "hello world"
  3 | 


Top-level evaluations are ignored
```
is an error of category `side_effect`.

#### Explanation
We may want to ignore some categories of errors in order to focus on other errors in a CI system for example.

## error_filename_blacklist
#### Example
```
"error_filename_blacklist": [
  "src/proto_alpha/lib_protocol/alpha_context.ml",
  "src/proto_alpha/lib_protocol/alpha_context.mli"
]
```

#### Value
A list of file names on which not to fail, even in case of errors. The return code of coq-of-ocaml is then 0 (success). We still display the error messages.

#### Explanation
We may still want to see the error logs of some complicated files while not returning a fatal error.

## error_message_blacklist
#### Example
```
"error_message_blacklist": [
  "Unbound module Tezos_protocol_alpha_functor"
]
```

#### Value
A list of strings used to filtered out the error messages. An error message containing such a string is ignored.

#### Explanation
We may want to ignore an error after manual inspection. This option allows to ignore an arbitrary error based on its error message.

## escape_value
#### Example
```
"escape_value": [
  "a",
  "baking_rights_query",
  "json"
]
```

#### Value
A list of variable names to escape. We escape by replacing a name `foo` by `__foo_value`. We do not escape type names or modules names.

#### Explanation
In OCaml, the value and type namespaces are different. For example, we can have a string named `string` of type `string`. In Coq, we need to find an alternate name in order to avoid a name collision. If you have a name collision due to a value having the same name as a type, you can use this option to escape the value name (and only the value name).

## first_class_module_path_blacklist
#### Example
```
"first_class_module_path_blacklist": [
  "Tezos_raw_protocol_alpha"
]
```

#### Value
A list of module names, typically corresponding to the module of a folder. All the modules which are direct children of such modules are considered as plain modules. They are encoded by Coq modules, even if there is a signature to make a corresponding record.

#### Explanation
The module system of coq-of-ocaml encodes the modules having a signature name as dependent records. We use the signature name as the record type name. Sometimes, for modules corresponding to files, we want to avoid using records even if there is a named signature. This option prevents the record encoding for modules of the form `A.B` where `A` is in the black-list. For example, when a reference to a value `A.B.c` appears, we generate `A.B.c` rather than `A.B.(signature_name_of_B.c)`. Indeed, `A.B` is a Coq module rather than a record.

## head_suffix
#### Example
```
"head_suffix": "Import Environment.Notations.\n"
```

#### Value
A string to add in the header of each file.

#### Explanation
We can use this option to add some default imports, or turn on some notations or flags.

## monadic_operators
#### Example
```
"monadic_operators": [
  ["Error_monad.op_gtgteq", "let="],
  ["Error_monad.op_gtgteqquestion", "let=?"],
  ["Error_monad.op_gtgtquestion", "let?"]
]
```

#### Value
A list of couples of a monadic operator name and a monadic notation to use by coq-of-ocaml. You still have to define the notations somewhere, such as:
```coq
Notation "'let?' x ':=' X 'in' Y" :=
  (Error_monad.op_gtgtquestion X (fun x => Y))
  (at level 200, x ident, X at level 100, Y at level 200).

Notation "'let?' ' x ':=' X 'in' Y" :=
  (Error_monad.op_gtgtquestion X (fun x => Y))
  (at level 200, x pattern, X at level 100, Y at level 200).
```
The binder `x` can be a variable name or a pattern prefixed by `'`.

#### Explanation
This helps to improve readability of code with effects written in a monadic style. For example:
```ocaml
(* let (>>=) x f = ... *)

let operate x =
  operation1 x >>= fun (y, z) ->
  operation2 y z
```
will generate, thanks to the notation mechanism:
```coq
Definition operate (x : string) : int :=
  let! '(y, z) := operation1 x in
  operation2 y z.
```
Note that you can also use the monadic notation in OCaml with the [binding operators](https://caml.inria.fr/pub/docs/manual-ocaml/bindingops.html).

## require
#### Example
```
"require": [
  ["Tezos_raw_protocol_alpha", "Tezos"]
]
```

#### Value
A list of couples of a module name and a module to require from in Coq.

#### Explanation
When we import a project with many files in Coq, we need to add the relevant `Require` directives for external references. For a require rule `["A", "B"]`, when we see in OCaml a reference to the module `A.M`, we generate in Coq the reference `M`. We also add a `Require B.M.` at the top of the file.

## require_import
#### Example
```
"require_import": [
  ["Tezos_protocol_environment_alpha", "Tezos"]
]
```

#### Value
A list of couples of a module name and a module to require import from in Coq.

#### Explanation
Similar to the `require` command, with an additional `Import` in order to shorten the paths for commonly used modules.

## require_long_ident
#### Example
```
"require_long_ident": [
  ["Storage_description", "Tezos"]
]
```

#### Value
A list of module names and module namespaces to require from.

#### Explanation
In some cases, it is not possible to get the right `Require` directive for an external reference. In particular when there is a long identifier rather than a path in the OCaml AST. With a rule `["A", "B"]`, a reference to the module `A` also generates the same reference `A` but adds a `Require B.A.` at the top of the output.

## require_mli
#### Example
```
"require_mli": [
  "Storage",
  "Storage_functors"
]
```

#### Value
A list of files to require as `.mli` rather than as `.ml`. The files are described by their corresponding module name.

#### Explanation
In OCaml, there are two kinds of files, namely `.ml` and `.mli` files. We import both with coq-of-ocaml, but only the `.ml` file is complete and sufficient. The `.mli` import corresponds to axioms without the definitions. However, sometimes the import of the `.ml` version fails but the `.mli` works. Then, we may want to use the imported `.mli` as a dependency in the `Require` directive rather than the imported `.ml` version.

## variant_constructors
#### Example
```
"variant_constructors": [
  ["Dir", "Context.Dir"],
  ["Key", "Context.Key"],
  ["Uint16", "Data_encoding.Uint16"],
  ["Uint8", "Data_encoding.Uint8"],
  ["Hex", "MBytes.Hex"]
]
```

#### Value
A list of polymorphic variant constructor names in OCaml and constructor names in Coq.

#### Explanation
Coq supports algebraic types through the `Inductive` keyword, but there are no direct equivalents for [polymorphic variants](https://caml.inria.fr/pub/docs/manual-ocaml/lablexamples.html#s:polymorphic-variants). We can replace many occurrences of polymorphic variants by standard algebraic types, updating the input code to help coq-of-ocaml. Sometimes, a direct modification of the source is not possible. We can then explain to coq-of-ocaml how to deal with polymorphic variants as if they were inductive types.

When there is a type definition with a polymorphic variant, coq-of-ocaml transforms it to the closest inductive:
```ocaml
module Context = struct
  type t = [`Dir | `Key]
end
```
generates:
```coq
Module Context.
  Inductive t : Set :=
  | Dir : t
  | Key : t.
End Context.
```
When a constructor appears, this option helps to tell Coq from which module it is. For example:
```ocaml
let x : Context.t = `Dir
```
would be transformed to:
```coq
Definition x : Context.t := Dir.
```
which is incorrect. By giving the relation `["Dir", "Context.Dir"]`, we can tell coq-of-ocaml to generate the correct constructor with the correct module prefix:
```coq
Definition x : Context.t := Context.Dir.
```

## variant_types
#### Example
```
"variant_types": [
  ["Dir", "Context.key_or_dir"],
  ["Key", "Context.key_or_dir"]
]
```

#### Value
A list of couples of a polymorphic variant constructor and a type name to use when the constructor appears.

#### Explanation
When we name a polymorphic variant with a type synonym:
```ocaml
type t = [`Dir | `Key]
```
an expression could still have a type without mentioning `t`:
```ocaml
let x : [`Dir] = `Dir
```
Since the polymorphic variants do not have a direct equivalent in OCaml, we could instead use a standard algebraic type:
```ocaml
type t = Dir | Key

let x : t = Dir
```
which translates to:
```coq
Inductive t : Set :=
| Dir : t
| Key : t.

Definition x : t := Dir.
```

When removing polymorphic variants is not possible, coq-of-ocaml transforms the type definition to the closest inductive type:
```coq
Inductive t : Set :=
| Dir : t
| Key : t.
```
and with the setting `["Dir", "t"]` it also correctly transforms the type of `x`:
```coq
Definition x : t := Dir.
```

## without_guard_checking
#### Example
```
"without_guard_checking": [
  "src/proto_alpha/lib_protocol/apply.ml",
  "src/proto_alpha/lib_protocol/misc.ml",
  "src/proto_alpha/lib_protocol/raw_context.ml",
  "src/proto_alpha/lib_protocol/script_interpreter.ml",
  "src/proto_alpha/lib_protocol/storage_description.ml"
]
```

#### Value
A list of filenames on which to disable termination checks by Coq.

#### Explanation
This option turns off the flag `Guard Checking`:
```coq
Unset Guard Checking.
```
Thus it is possible to write fixpoints which are not syntactically terminating. To help the evaluation tactics to terminate in the proofs, we can combine this setting with the [coq_struct](http://localhost:3000/coq-of-ocaml/docs/attributes#coq_struct) attribute.

For example, the following OCaml code:
```ocaml
(* let split_at (c : char) (s : string) : (string * string) option = ... *)

let rec split_all (c : char) (s : string) : string list =
  match split_at c s with
  | None -> [s]
  | Some (s1, s2) -> s1 :: split_all c s2
```
generates:
```coq
Fixpoint split_all (c : ascii) (s : string) : list string :=
  match split_at c s with
  | None => [ s ]
  | Some (s1, s2) => cons s1 (split_all c s2)
  end.
```
which is not accepted by Coq with the error:
```
Error: Cannot guess decreasing argument of fix.
```
despite the fact that we know that `split_at` should always return a smaller string. By disabling the guard checking, we can force Coq to accept this example of code. We automatically add a `struct` annotation on the first fixpoint argument so that Coq accepts the definition:
```coq
Fixpoint split_all (c : ascii) (s : string) {struct c} : list string :=
  match split_at c s with
  | None => [ s ]
  | Some (s1, s2) => cons s1 (split_all c s2)
  end.
```
However, we must be cautious as a `struct` annotation may break the symbolic evaluation of `split_all` since `c` never changes in recursive calls. For example:
```coq
Parameter P : ascii -> string -> list string -> Prop.

Lemma split_all_property (c : ascii) (s : string) : P c s (split_all c s).
  destruct c; simpl.
```
produces:
```
Error: Stack overflow.
```
because `split_all` is infinitely unfolded. With the `coq_struct` attribute we can force the `struct` annotation to be on the argument `s`:
```ocaml
let rec split_all (c : char) (s : string) : string list =
  match split_at c s with
  | None -> [s]
  | Some (s1, s2) -> s1 :: split_all c s2
[@@coq_struct "s"]
```
produces:
```coq
Fixpoint split_all (c : ascii) (s : string) {struct s} : list string :=
  match split_at c s with
  | None => [ s ]
  | Some (s1, s2) => cons s1 (split_all c s2)
  end.
```
Then, neither:
```coq
destruct c; simpl.
```
nor:
```coq
destruct s; simpl.
```
breaks. For more information about the reduction strategies in Coq proofs, you can start with the documentation of the [simpl tactic](https://coq.inria.fr/refman/proof-engine/tactics.html#coq:tacn.simpl).

## without_positivity_checking
#### Example
```
"without_positivity_checking": [
  "src/proto_alpha/lib_protocol/storage_description.ml"
]
```

#### Value
A list of filenames on which to disable the positivity checking.

#### Explanation
This option turns off the flag `Positivity Checking`:
```coq
Unset Positivity Checking.
```
This allows to define types which would not respect the strict positivity condition:
```ocaml
type t = L of (t -> t)
```
generates:
```coq
Inductive t : Set :=
| L : (t -> t) -> t.
```
which without this setting gives this error in Coq:
```
Error: Non strictly positive occurrence of "t" in "(t -> t) -> t".
```
