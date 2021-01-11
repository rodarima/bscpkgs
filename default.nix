let
  bscOverlay = import ./overlay.nix;

  # Pin the nixpkgs
  nixpkgsPath = builtins.fetchTarball {
    # Descriptive name to make the store path easier to identify
    name = "nixos-20.09";
    # Commit hash for nixos-20.09 as of 2021-01-11
    url = "https://github.com/nixos/nixpkgs/archive/41dddb1283733c4993cb6be9573d5cef937c1375.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1blbidbmxhaxar2x76nz72bazykc5yxi0algsbrhxgrsvijs4aiw";
  };

  pkgs = import nixpkgsPath {
    overlays = [ bscOverlay ];
  };

in pkgs
