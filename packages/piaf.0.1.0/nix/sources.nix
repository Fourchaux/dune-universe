{ ocamlVersion ? "4_11" }:
let
  overlays =
    /Users/anmonteiro/projects/nix-overlays;
  # builtins.fetchTarball
  # https://github.com/anmonteiro/nix-overlays/archive/1871871.tar.gz;

in
import "${overlays}/sources.nix" {
  overlays = [
    (import overlays)
    (self: super: {
      ocamlPackages = super.ocaml-ng."ocamlPackages_${ocamlVersion}";

      pkgsCross.musl64 = super.pkgsCross.musl64 // {
        ocamlPackages = super.pkgsCross.musl64.ocaml-ng."ocamlPackages_${ocamlVersion}";
      };
    })
  ];
}
