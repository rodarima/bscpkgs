let
  bscOverlay = import ./overlay.nix;

  commit = "9a6aabc4740790ef3bbb246b86d029ccf6759658";

  # Pin the nixpkgs
  nixpkgsPath = builtins.fetchTarball {
    # Descriptive name to make the store path easier to identify
    name = "nixpkgs-${commit}";
    # Commit hash for nixpkgs as of 2023-04-11
    url = "https://github.com/nixos/nixpkgs/archive/${commit}.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0m8cid2n6zfnbia7kkan9vw8n5dvwn8sv7cmrap46rckpzbahnls";
  };

  pkgs = import nixpkgsPath {
    overlays = [ bscOverlay ];
  };

in pkgs
