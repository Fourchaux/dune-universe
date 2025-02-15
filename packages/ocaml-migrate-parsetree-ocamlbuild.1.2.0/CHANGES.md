v1.2.0 2018-12-19 London
------------------------

- Remove unused ocamlfind dependency in the opam file (#53, @diml)

- Add `--print-transformations` to list registered transformations
  (#55, @rgrinberg)

- Fix Windows compatibility by setting the output to binary mode when
  writing a binary ast (#57, #59, @bryphe and @dra27)

- Switch to dune and opam 2.0 (#58, #60, @diml)

v1.1.0 2018-09-05 London
------------------------

- Allow ppx rewriters to specify when they should be applied

v1.0.11 2018-06-06 London
-------------------------

- Fix handling of `--impl/--intf`. Before the driver would crash if
  the file extension was neither `.ml` nor `.mli`

v1.0.10 2018-04-19 London
-------------------------

- Add support for OCaml 4.07

v1.0.9 2018-03-20 New York
--------------------------

- Fix an issue where cookies set from the command line sometimes
  disappeared

v1.0.8 2018-03-15 London
------------------------

- Add a `--null` argument to suppress the output. This is used to
  write linters
- Use the new generic ppx driver support of jbuilder

v1.0.7 2017-10-31 Paris
-----------------------

Contributed by @hhugo:
- update Magic Number for 4.06
- fix some compilation warnings

v1.0.6 2017-10-11 Paris
-----------------------

Fix generation of `Migrate_parsetree` module.

v1.0.5 2017-10-02 Paris
-----------------------

Resynchronize with trunk.
Add a migrating version of Parse module.

v1.0.4 2017-08-22 Paris
-----------------------

Resynchronize with trunk. Contributed by Xavier Clerc, @xclerc.

v1.0.3 2017-08-11 Paris
-----------------------

Add a shallow identity mapper (suggested by Anton Bachin, @aantron).

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
