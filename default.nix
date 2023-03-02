let
  bscOverlay = import ./overlay.nix;

  commit = "3c0a90afd70b46b081601f9941999e596576337f";

  # Pin the nixpkgs
  nixpkgsPath = builtins.fetchTarball {
    # Descriptive name to make the store path easier to identify
    name = "nixpkgs-${commit}";
    # Commit hash for nixpkgs release-22.11 as of 2023-03-02
    url = "https://github.com/nixos/nixpkgs/archive/${commit}.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0ss4cigiph1ck4lr0qjiw79pjsi4q0nd00mjfzmzmarxdphjsmyy";
  };

  pkgs = import nixpkgsPath {
    overlays = [ bscOverlay ];
  };

in pkgs
