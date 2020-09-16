let
  bscOverlay = import ./overlay.nix;
  pkgs = import <nixpkgs> {
    overlays = [ bscOverlay ];
  };

in pkgs
