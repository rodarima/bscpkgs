let
  bscOverlay = import ./overlay.nix;

  commit = "d6b863fd9b7bb962e6f9fdf292419a775e772891";

  # Pin the nixpkgs
  nixpkgsPath = builtins.fetchTarball {
    # Descriptive name to make the store path easier to identify
    name = "nixpkgs-${commit}";
    url = "https://github.com/nixos/nixpkgs/archive/${commit}.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "02rd1n6d453rdp2978bvnp99nyfa26jxgbsg78yb9mmdxvha3hnr";
  };

  pkgs = import nixpkgsPath {
    overlays = [ bscOverlay ];
  };

in pkgs
