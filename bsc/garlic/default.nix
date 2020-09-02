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
    inherit bsc;

    mpptest = callPackage ./mpptest { };

    ppong = callPackage ./ppong {
      mpi = bsc.mpi;
    };

    nbody = callPackage ./nbody {
      cc = bsc.icc;
      mpi = bsc.impi;
      gitBranch = "garlic/seq";
    };

    sbatchWrapper = callPackage ./sbatch.nix { };
    srunWrapper = callPackage ./srun.nix { };
    launchWrapper = callPackage ./launcher.nix { };
    controlWrapper = callPackage ./control.nix { };
    nixsetupWrapper = callPackage ./nix-setup.nix { };
    argvWrapper = callPackage ./argv.nix { };
    statspyWrapper = callPackage ./statspy.nix { };
    extraeWrapper = callPackage ./extrae.nix { };

    # Perf is tied to a linux kernel specific version
    linuxPackages = bsc.linuxPackages_4_4;
    perfWrapper = callPackage ./perf.nix {
      perf = linuxPackages.perf;
    };

    exp = {
      nbody = {
        bs = callPackage ./exp/nbody/bs.nix { };
        mpi = callPackage ./exp/nbody/mpi.nix { };
      };
      osu = rec {
        latency-internode = callPackage ./exp/osu/latency.nix { };
        latency-intranode = callPackage ./exp/osu/latency.nix {
          interNode = false;
        };
        latency = latency-internode;
      };
    };
  };

in
  garlic
