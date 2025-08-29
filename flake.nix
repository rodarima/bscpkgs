{
  inputs.nixpkgs.url = "nixpkgs";

  outputs = { self, nixpkgs, ...}:
  let
    pkgs = import nixpkgs {
      # For now we only support x86
      system = "x86_64-linux";
      overlays = [ self.overlays.default ];
    };
  in
    {
      bscOverlay = import ./overlay.nix;
      overlays.default = self.bscOverlay;
      legacyPackages.x86_64-linux = pkgs;

      # propagate nixpkgs lib, so we can do bscpkgs.lib
      inherit (nixpkgs) lib;
    };
}
