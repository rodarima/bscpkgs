{
  inputs.nixpkgs.url = "nixpkgs";

  outputs = { self, nixpkgs, ...}:
    let
      # For now we only support x86
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      bscOverlay = import ./overlay.nix;
      overlays.default = self.bscOverlay;
      # full nixpkgs with our overlay applied
      legacyPackages.${system} = pkgs;

      hydraJobs = {
        inherit (self.legacyPackages.${system}.bsc-ci) test pkgs;
      };

      # propagate nixpkgs lib, so we can do bscpkgs.lib
      inherit (nixpkgs) lib;
    };
}
