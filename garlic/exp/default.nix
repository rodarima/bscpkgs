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
      sbatch  = callPackage ./stages/sbatch.nix { };
      srun    = callPackage ./stages/srun.nix { };
      launch  = callPackage ./stages/launcher.nix { };
      control = callPackage ./stages/control.nix { };
      nixsetup= callPackage ./stages/nix-setup.nix { };
      argv    = callPackage ./stages/argv.nix { };
      statspy = callPackage ./stages/statspy.nix { };
      extrae  = callPackage ./stages/extrae.nix { };
      stagen  = callPackage ./stages/stagen.nix { };
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
