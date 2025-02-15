# override 0.3.0, 2020-05-18

- support for OCaml 4.11.0

- relies on `metapp` and `metaquot`.
  `ppxlib` and `ppx_deriving` are not dependencies anymore.

# override 0.2.2, 2019-09-27

- support for OCaml 4.09.0

- compatible with the latest versions of ppxlib and ppx_deriving

# override 0.2.1, 2019-07-04

- attributes applied on `[%%types]` are applied once by declaration
  group. (Previously, attributes were applied to each types in a group,
  leading ppxlib's deriving to make n * n expansions for a group of
  n types -- one for each type/attribute pair).

# override 0.2.0, 2019-07-01

- compatibility with OCaml 4.08.0

- remove dependency to ppx_tools

- add examples/typedtree_collect_texp_apply

- bootstrapped equivalence checking for Parsetree.core_type: matching
  between types for applying rewriting rules is now complete, and is
  implemented by overriding Parsetree and deriving eq. The former
  incomplete equivalence checking is used to bootstrap.

- support aliases even if the target module is defined in the same
  module (we do not take declaration order into account yet, so there
  can be wrong shadowings, and even loops, even if we suppress the
  trivial ones).

- renamed types are substituded globally in mutually recursive type
  definitions.

# override 0.1.0, 2019-05-09

- generalizes ppx_import by allowing a whole module to be imported
  with all its types, possibly with annotations.

- module overriding: mechanization of Gabriel Scherer's post on Gagallium blog
  http://gallium.inria.fr/blog/overriding-submodules/

- type rewriting: types can be systematically annotated, substituted,
  renamed, or removed. Transformations such as those that are described in
  the comments of ast/ast.ml in ppxlib sources can be mechanized.
