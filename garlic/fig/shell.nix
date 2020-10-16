{ pkgs ? import ../../default.nix }:

with pkgs;

let
  rWrapper = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [ tidyverse ];
  };
in
stdenv.mkDerivation {
  name = "R";

  buildInputs = [ rWrapper ];
}
