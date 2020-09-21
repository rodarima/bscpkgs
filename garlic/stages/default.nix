{
  pkgs
, callPackage
, callPackages
}:

let

  garlic = {

    # Load some helper functions to generate app variants
    inherit (import ./gen.nix) genApps genApp genConfigs;

    mpptest = callPackage ./mpptest { };

    ppong = callPackage ./ppong {
      mpi = pkgs.mpi;
    };

    nbody = callPackage ./nbody {
      cc = pkgs.icc;
      mpi = pkgs.impi;
      tampi = pkgs.tampi;
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
    linuxPackages = pkgs.linuxPackages_4_4;
    perfWrapper = callPackage ./perf.nix {
      perf = pkgs.linuxPackages.perf;
    };

    exp = {
      noise = callPackage ./exp/noise.nix { };
      nbody = {
        bs = callPackage ./exp/nbody/bs.nix {
          pkgs = pkgs // garlic;
        };
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
