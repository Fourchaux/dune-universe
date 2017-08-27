## v0.3

* Port build to jbuilder and export an OCaml library with the Parts interface
  for the sexpression output of `ocaml-topexpect`.
* Pass -linkall flag when linking `ocaml-topexpect` binary.
* Preserve comments that get attached to `[%%expect]` and `[@@@part]` items.

## v0.2

* Various API improvements as the tool is integrated into Real World OCaml v2
* Add support for non-deterministic expect tests which can have different
  outputs.

## v0.1

* Initial public release.
