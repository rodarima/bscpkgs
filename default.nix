let
  bscOverlay = import ./overlay.nix;

  # Pin the nixpkgs
  nixpkgsPath = import ./nixpkgs.nix;

  pkgs = import nixpkgsPath {
    overlays = [ bscOverlay ];
  };

in pkgs
