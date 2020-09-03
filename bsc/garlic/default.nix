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

    runWrappers = {
      sbatch  = callPackage ./sbatch.nix { };
      srun    = callPackage ./srun.nix { };
      launch  = callPackage ./launcher.nix { };
      control = callPackage ./control.nix { };
      nixsetup= callPackage ./nix-setup.nix { };
      argv    = callPackage ./argv.nix { };
      statspy = callPackage ./statspy.nix { };
      extrae  = callPackage ./extrae.nix { };
      stagen  = callPackage ./stagen.nix { };
    };

    # Perf is tied to a linux kernel specific version
    linuxPackages = bsc.linuxPackages_4_4;
    perfWrapper = callPackage ./perf.nix {
      perf = linuxPackages.perf;
    };

    exp = {
      noise = callPackage ./exp/noise.nix { };
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
