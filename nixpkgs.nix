let
  commit = "d680ded26da5cf104dd2735a51e88d2d8f487b4d";
in builtins.fetchTarball {
    # Descriptive name to make the store path easier to identify
    name = "nixpkgs-${commit}";
    url = "https://github.com/nixos/nixpkgs/archive/${commit}.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0xczslr40zy1wlg0ir8mwyyn5gz22i2f9dfd0vmgnk1664v4chky";
}
