{
  pkgs
, bsc
}:

let
  callPackage = pkgs.lib.callPackageWith (pkgs // bsc // garlic);
  callPackages = pkgs.lib.callPackagesWith (pkgs // bsc // garlic);
  garlic = rec {
    mpptest = callPackage ./mpptest/default.nix { };
    ppong = callPackage ./ppong/default.nix { };
  };
in
  garlic
