let
  bscOverlay = import ./overlay.nix;

  # read flake.lock and determine revision from there
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  inherit (lock.nodes.nixpkgs.locked) rev narHash;
  fetchedNixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    sha256 = narHash;
  };
in
{ overlays ? [ ]
, nixpkgs ? fetchedNixpkgs
, ...
}@attrs:
import nixpkgs (
  (builtins.removeAttrs attrs [ "overlays" "nixpkgs" ]) //
  { overlays = [ bscOverlay ] ++ overlays; }
)
