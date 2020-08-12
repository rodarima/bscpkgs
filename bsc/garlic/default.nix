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

    sbatchWrapper = callPackage ./sbatch.nix { };
    launcherWrapper = callPackage ./launcher.nix { };
    controlWrapper = callPackage ./control.nix { };
    nixsetupWrapper = callPackage ./nix-setup.nix { };
    argvWrapper = callPackage ./argv.nix { };

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
