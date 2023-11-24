let
  commit = "e4ad989506ec7d71f7302cc3067abd82730a4beb";
in builtins.fetchTarball {
    # Descriptive name to make the store path easier to identify
    name = "nixpkgs-${commit}";
    url = "https://github.com/nixos/nixpkgs/archive/${commit}.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "sha256-de9KYi8rSJpqvBfNwscWdalIJXPo8NjdIZcEJum1mH0=";
}
