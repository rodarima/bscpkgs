self:  /* Future last stage */
super: /* Previous stage */

let
  #callPackage = self.callPackage;
  inherit (self.lib) callPackageWith;
  inherit (self.lib) callPackagesWith;
  callPackage = callPackageWith (self // self.bsc);

  bsc = {
    # Default MPI implementation to use. Will be overwritten by the
    # experiments.
    mpi = self.bsc.openmpi;

    # --------------------------------------------------------- #
    #  BSC Packages
    # --------------------------------------------------------- #

    perf = callPackage ./bsc/perf/default.nix {
      kernel = self.linuxPackages_4_9.kernel;
      systemtap = self.linuxPackages_4_9.systemtap;
    };

    # ParaStation MPI
    pscom = callPackage ./bsc/parastation/pscom.nix { };
    psmpi = callPackage ./bsc/parastation/psmpi.nix { };

    osumb = callPackage ./bsc/osu/default.nix { };

    mpich = callPackage ./bsc/mpich/default.nix { };

    mpichDebug = self.mpich.override { enableDebug = true; };

    # Default Intel MPI version is 2019 (the last one)
    impi = self.bsc.intelMpi;

    intelMpi = self.bsc.intelMpi2019;

    intelMpi2019 = callPackage ./bsc/intel-mpi/default.nix {
      # Intel MPI provides a debug version of the MPI library, but
      # by default we use the release variant for performance
      enableDebug = false;
    };

    # By default we use Intel compiler 2020 update 1
    iccUnwrapped = self.bsc.icc2020Unwrapped;

    icc2020Unwrapped = callPackage ./bsc/intel-compiler/icc2020.nix {
      intel-mpi = self.bsc.intelMpi;
    };

    # A wrapper script that puts all the flags and environment vars properly and
    # calls the intel compiler binary
    icc = callPackage ./bsc/intel-compiler/default.nix {
      iccUnwrapped = self.bsc.iccUnwrapped;
      intelLicense = self.bsc.intelLicense;
    };

    intelLicense = callPackage ./bsc/intel-compiler/license.nix { };

    pmix2 = callPackage ./bsc/pmix/pmix2.nix { };

    slurm17 = callPackage ./bsc/slurm/default.nix {
      pmix = self.bsc.pmix2;
    };

    slurm17-libpmi2 = callPackage ./bsc/slurm/pmi2.nix {
      pmix = self.bsc.pmix2;
    };

    openmpi-mn4 = callPackage ./bsc/openmpi/default.nix {
      pmix = self.bsc.pmix2;
      pmi2 = self.bsc.slurm17-libpmi2;
      enableCxx = true;
    };

    openmpi = self.bsc.openmpi-mn4;

    fftw = callPackage ./bsc/fftw/default.nix {
      mpi = self.bsc.mpi;
    };

    extrae = callPackage ./bsc/extrae/default.nix {
      mpi = self.bsc.mpi;
    };

    tampi = callPackage ./bsc/tampi/default.nix {
      mpi = self.bsc.mpi;
    };

    mcxx = callPackage ./bsc/mcxx/default.nix { };

    mcxx-rarias = callPackage ./bsc/mcxx/rarias.nix { };

    # Use nanos6 git by default
    nanos6 = self.nanos6-git;
    nanos6-latest = callPackage ./bsc/nanos6/default.nix {
      extrae = self.bsc.extrae;
    };

    nanos6-git = callPackage ./bsc/nanos6/git.nix {
      extrae = self.bsc.extrae;
    };

    vtk = callPackage ./bsc/vtk/default.nix {
      mpi = self.bsc.mpi;
      inherit (self.xorg) libX11 xorgproto libXt;
    };

    dummy = callPackage ./bsc/dummy/default.nix { };

    clang-ompss2-unwrapped = callPackage ./bsc/llvm-ompss2/clang.nix {
      stdenv = self.llvmPackages_10.stdenv;
      enableDebug = false;
    };

    clang-ompss2 = callPackage bsc/llvm-ompss2/default.nix {
      clang-ompss2-unwrapped = self.bsc.clang-ompss2-unwrapped;
    };

    stdenvOmpss2 = self.clangStdenv.override {
      cc = self.bsc.clang-ompss2;
    };

    cpic = callPackage ./bsc/apps/cpic/default.nix {
      stdenv = self.bsc.stdenvOmpss2;
      mpi = self.bsc.mpi;
      tampi = self.bsc.tampi;
    };

    mpptest = callPackage ./bsc/mpptest/default.nix { };


    garlic = {

      # Load some helper functions to generate app variants
      inherit (import ./bsc/garlic/gen.nix) genApps genApp genConfigs;

      mpptest = callPackage ./bsc/garlic/mpptest { };

      ppong = callPackage ./bsc/garlic/ppong {
        mpi = self.bsc.mpi;
      };

      nbody = callPackage ./bsc/garlic/nbody {
        cc = self.bsc.icc;
        mpi = self.bsc.impi;
        tampi = self.bsc.tampi;
        gitBranch = "garlic/seq";
      };

      runWrappers = {
        sbatch  = callPackage ./bsc/garlic/sbatch.nix { };
        srun    = callPackage ./bsc/garlic/srun.nix { };
        launch  = callPackage ./bsc/garlic/launcher.nix { };
        control = callPackage ./bsc/garlic/control.nix { };
        nixsetup= callPackage ./bsc/garlic/nix-setup.nix { };
        argv    = callPackage ./bsc/garlic/argv.nix { };
        statspy = callPackage ./bsc/garlic/statspy.nix { };
        extrae  = callPackage ./bsc/garlic/extrae.nix { };
        stagen  = callPackage ./bsc/garlic/stagen.nix { };
      };

      # Perf is tied to a linux kernel specific version
      linuxPackages = self.linuxPackages_4_4;
      perfWrapper = callPackage ./bsc/garlic/perf.nix {
        perf = self.linuxPackages.perf;
      };

      exp = {
        noise = callPackage ./bsc/garlic/exp/noise.nix { };
        nbody = {
          bs = callPackage ./bsc/garlic/exp/nbody/bs.nix {
            pkgs = self // self.bsc.garlic;
            nixpkgs = import <nixpkgs>;
            genApp = self.bsc.garlic.genApp;
            genConfigs = self.bsc.garlic.genConfigs;
            runWrappers = self.bsc.garlic.runWrappers;
          };
#          mpi = callPackage ./bsc/garlic/exp/nbody/mpi.nix { };
        };
        osu = rec {
          latency-internode = callPackage ./bsc/garlic/exp/osu/latency.nix { };
          latency-intranode = callPackage ./bsc/garlic/exp/osu/latency.nix {
            interNode = false;
          };
          latency = latency-internode;
        };
      };
    };
  };

in
  {
    bsc = bsc;
  }
