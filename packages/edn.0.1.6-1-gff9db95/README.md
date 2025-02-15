edn — Parsing OCaml library for EDN format
-------------------------------------------------------------------------------
v0.1.6-1-gff9db95

This library implements [EDN][edn] parser and generator for OCaml.

Homepage: https://github.com/prepor/edn
Contact: Andrew Rudenko `<ceo@prepor.ru>`


## Installation

edn can be installed with `opam`:

    opam install edn

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Usage

``` ocaml
Edn.from_string "{:a #foo/bar [1 2 3]}";;
- : Edn.t = `Assoc [(`Keyword (None, "a"), `Tag (Some "foo", "bar", `Vector [`Int 1; `Int 2; `Int 3]))]
```

## PPX generator

There is [cconv][cconv] encoder/decoder in `edn.cconv` package. You can use it with `cconv.ppx` to generate encoders/decoders from/to your types.

``` ocaml
type book = { title : string; quantity : int} [@@deriving cconv]
type library = { books : book list } [@@deriving cconv];;

Edn_cconv.of_string_exn decode_library "{:books [{:title \"The Catcher in the Rye\" :quantity 10}]}";;
- : library = {books = [{title = "The Catcher in the Rye"; quantity = 10}]}
```

## Documentation

The documentation and API reference is automatically generated by
`ocamldoc` from the interfaces. It can be consulted [online][doc]
and there is a generated version in the `doc` directory of the
distribution.

[edn]: https://github.com/edn-format/edn
[cconv]: https://github.com/c-cube/cconv/
[doc]: https://prepor.github.io/ocaml-edn/doc

