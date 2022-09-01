let
  bscOverlay = import ./overlay.nix;

  commit = "1614b96a68dd210919865abe78bda56b501eb1ef";

  # Pin the nixpkgs
  nixpkgsPath = builtins.fetchTarball {
    # Descriptive name to make the store path easier to identify
    name = "nixpkgs-${commit}";
    # Commit hash for nixpkgs as of 2021-09-01
    url = "https://github.com/nixos/nixpkgs/archive/${commit}.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "17c4a6cg0xmnp6hl76h8fvxglngh66s8nfm3qq2iqv6iay4a92qz";
  };

  pkgs = import nixpkgsPath {
    overlays = [ bscOverlay ];
  };

in pkgs
