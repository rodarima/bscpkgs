{
  pkgs
, bsc
}:

let
  callPackage = pkgs.lib.callPackageWith (pkgs // bsc // garlic);
  callPackages = pkgs.lib.callPackagesWith (pkgs // bsc // garlic);

  garlic = rec {

    # Load some helper functions to generate app variants
    inherit (import ./gen.nix) genApps genApp genConfigs;

    mpptest = callPackage ./mpptest { };

    ppong = callPackage ./ppong {
      mpi = bsc.mpi;
    };

    nbody = callPackage ./nbody {
      cc = pkgs.gcc7;
      gitBranch = "garlic/seq";
    };

    sbatch = callPackage ./sbatch.nix { };
    launcher = callPackage ./launcher.nix { };

    exp = {
      nbody = {
        bs = callPackage ./exp/nbody/bs.nix {
          inherit bsc;
        };
      };
    };
  };

in
  garlic
