## ppx_irmin

PPX extension for automatically generating Irmin generics.

### Overview

`ppx_irmin` automatically generates Irmin generics (values of type
`_ Irmin.Type.t`) corresponding to type declarations in your code. For example:

```ocaml
type tree =
  | Branch of tree * bool option * tree
  | Leaf of int32 * string [@@deriving irmin]
```

will be expanded to:

```ocaml
type tree = (* as above *)

let tree_t =
  let open Irmin.Type in
  mu (fun tree_t ->
      variant "tree" (fun branch leaf -> function
          | Branch (x1, x2, x3) -> branch (x1, x2, x3)
          | Leaf   (x1, x2)     -> leaf (x1, x2))
      |~ case1 "Branch" (triple tree_t (option bool) tree_t) (fun (x1, x2, x3) -> Branch (x1, x2, x3))
      |~ case1 "Leaf"   (pair int32 string)                  (fun (x1, x2) -> Leaf (x1, x2))
      |> sealv)
```

### Installation and usage

`ppx_irmin` may be installed via [opam](https://opam.ocaml.org/):

```
opam install ppx_irmin
```

If you're using the [dune](https://github.com/ocaml/dune) build system, add the
following field to your `library`, `executable` or `test` stanza:

```
(preprocess (pps ppx_irmin))
```

You can now use `[@@deriving irmin]` after a type declaration in your code to
automatically derive an Irmin generic with the same name.

### Specifics

`ppx_irmin` supports all of the type combinators exposed in the
[Irmin.Type](https://docs.mirage.io/irmin/Irmin/Type/index.html) module (basic
types, records, variants (plain and closed polymorphic), recursive types etc.).
Irmin does not currently support higher-kinded generics: all Irmin types must
fully grounded (no polymorphic type variables).

#### Naming scheme

The generated generics will be called `<type-name>_t`, unless the type-name is
`t`, in which case the generic is simply `t`. This behaviour can be overridden
using the `name` argument, as in:

```ocaml
type foo = string list * int32 [@@deriving irmin { name = "foo_generic" }]

(* generates the value *)
val foo_generic = Irmin.Type.(pair (list string) int32)
```

If the type references another user-defined type, `ppx_irmin` will expect the
generic for that type to use the standard naming scheme. This can be overridden
using the `[@generic ...]` attribute, as in:

```ocaml
type bar = (foo [@generic foo_generic], string) result [@@deriving irmin]

(* generates the value *)
val bar_t = Irmin.Type.(result foo_generic string)
```

#### Signature type definitions

The `ppx_irmin` deriver can also be used in signatures to expose the
auto-generated value:

```ocaml
module Contents : sig
  type t = int32 [@@deriving irmin]

  (* exposes generic in signature *)
  val t : t Irmin.Type.t

end = struct
  type t = int32 [@@deriving irmin]

  (* generates generic value *)
  val t = Irmin.Type.int32
end
```
