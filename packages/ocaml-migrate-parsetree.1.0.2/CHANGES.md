v1.0.2 2017-07-28 Paris
-----------------------

Synchronize with 4.06 AST with trunk.
Accept --cookie arguments also when run in --as-ppx mode.

v1.0.1 2017-06-06 Paris
-----------------------

Add support for trunk version (as of today...).

v1.0 2017-04-17 Paris
---------------------

Driver: add --as-pp and --embed-errors flags.

    --embed-errors causes the driver to embed exceptions raised by
    rewriters as extension points in the Ast
    
    --as-pp is a shorthand for: --dump-ast --embed-errors

Expose more primitives for embedding the driver.

Fix bug where `reset_args` functions where not being called.
Fix "OCaml OCaml" in error messages (contributed by Adrien Guatto). 

v0.7 2017-03-21 Mâcon
---------------------

Fix findlib predicates: 
- replace `omp_driver` by `ppx_driver`
- replace `-custom_ppx` by `-custom_ppx,-ppx_driver`

v0.6 2017-03-21 Mâcon
---------------------

Add documentation, examples, etc.

v0.5 2017-03-11 Mâcon
---------------------

Specify ocamlfind dependency in opam file (@yunxing).

v0.4 2017-03-10 Mâcon
---------------------

API cleanup and extension. Added driver. Switch to jbuilder.

v0.3 2017-02-16 Paris
----------------------

Use `-no-alias-deps` to prevent linking failure of `Compiler_libs` (referencing `Parsetree` and `Asttypes` which have no implementation).

v0.2 2017-02-07 London
----------------------

Install CMXS too (contributed @vbmithr).

v0.1 2017-02-02 London
----------------------

First release. 
