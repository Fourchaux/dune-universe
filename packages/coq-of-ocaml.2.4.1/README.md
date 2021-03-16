# ![Logo](https://clarus.github.io/coq-of-ocaml/img/rooster-48.png) coq-of-ocaml
> Import OCaml programs to Coq.

[![CI](https://github.com/clarus/coq-of-ocaml/workflows/CI/badge.svg?branch=master)](https://github.com/clarus/coq-of-ocaml/actions?query=workflow%3ACI)

**https://clarus.github.io/coq-of-ocaml/**

Start with the file `main.ml`:
```ocaml
type 'a tree =
  | Leaf of 'a
  | Node of 'a tree * 'a tree

let rec sum tree =
  match tree with
  | Leaf n -> n
  | Node (tree1, tree2) -> sum tree1 + sum tree2
```

Run:
```
coq-of-ocaml main.ml
```

Get a file `Main.v`:
```coq
Require Import CoqOfOCaml.CoqOfOCaml.
Require Import CoqOfOCaml.Settings.

Inductive tree (a : Set) : Set :=
| Leaf : a -> tree a
| Node : tree a -> tree a -> tree a.

Arguments Leaf {_}.
Arguments Node {_}.

Fixpoint sum (tree : tree int) : int :=
  match tree with
  | Leaf n => n
  | Node tree1 tree2 => Z.add (sum tree1) (sum tree2)
  end.
```

## Features
* core of OCaml (functions, let bindings, pattern-matching,...) ✔️
* type definitions (records, inductive types, synonyms, mutual types) ✔️
* modules as namespaces ✔️
* modules as dependent records (signatures, functors, first-class modules) ✔️
* projects with complex dependencies using `.merlin` files ✔️
* `.ml` and `.mli` files ✔️
* existential types ✔️
* partial support of GADTs 🌊
* partial support of polymorphic variants 🌊
* partial support of extensible types 🌊
* ignores side-effects ❌

Even in case of errors we try to generate some Coq code. The generated Coq code should be readable and with a size similar to the OCaml source. One should not hesitate to fix remaining compilation errors, by hand or with a script (name collisions, missing `Require`,...).

## Install
### Latest stable version
Using the package manager [opam](https://opam.ocaml.org/),
```
opam install coq-of-ocaml
```
### Current development version
To install the current development version:
```
opam pin add https://github.com/clarus/coq-of-ocaml.git#master
```

### Manually
Read the `coq-of-ocaml.opam` file at the root of the project to know the dependencies to install and get the list of commands to build the project.

## Usage
`coq-of-ocaml` compiles the `.ml` or `.mli` files using [Merlin](https://github.com/ocaml/merlin) to understand the dependencies of a project. One first needs to have a **compiled project** with a working configuration of Merlin. The basic command is:
```
coq-of-ocaml file.ml
```

You can start to experiment with the test files in `tests/` or look at our [online examples](https://clarus.github.io/coq-of-ocaml/examples/).

## License
MIT © Guillaume Claret.
