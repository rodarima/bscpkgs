self:  /* Future last stage */
super: /* Previous stage */

let
  inherit (self.lib) callPackageWith;
  inherit (self.lib) callPackagesWith;
  callPackage = callPackageWith (self // self.bsc);

  # --------------------------------------------------------- #
  #  BSC Packages
  # --------------------------------------------------------- #

  bsc = {
    # Default MPI implementation to use. Will be overwritten by the
    # experiments.
    mpi = self.bsc.impi;

    perf = callPackage ./bsc/perf/default.nix {
      kernel = self.linuxPackages_4_9.kernel;
      systemtap = self.linuxPackages_4_9.systemtap;
    };

    # ParaStation MPI
    pscom = callPackage ./bsc/parastation/pscom.nix { };
    psmpi = callPackage ./bsc/parastation/psmpi.nix { };

    osumb = callPackage ./bsc/osu/default.nix { };

    mpich = callPackage ./bsc/mpich/default.nix { };

    mpichDebug = self.bsc.mpich.override { enableDebug = true; };

    # Updated version of libpsm2: TODO push upstream.
    #libpsm2 = callPackage ./bsc/libpsm2/default.nix { };

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

    # Use a slurm compatible with MN4
    slurm = self.bsc.slurm17;

    openmpi-mn4 = callPackage ./bsc/openmpi/default.nix {
      pmix = self.bsc.pmix2;
      pmi2 = self.bsc.slurm17-libpmi2;
      enableCxx = true;
    };

    openmpi = self.bsc.openmpi-mn4;

    fftw = callPackage ./bsc/fftw/default.nix { };

    extrae = callPackage ./bsc/extrae/default.nix { };

    tampi = self.bsc.tampiGit;
    tampiRelease = callPackage ./bsc/tampi/default.nix { };
    tampiGit = callPackage ./bsc/tampi/git.nix { };

    mcxxGit = callPackage ./bsc/mcxx/default.nix {
      bison = self.bison_3_5;
    };

    mcxxRarias = callPackage ./bsc/mcxx/rarias.nix {
      bison = self.bison_3_5;
    };

    mcxx = self.bsc.mcxxGit;

    # Use nanos6 git by default
    nanos6 = self.bsc.nanos6Git;
    nanos6Latest = callPackage ./bsc/nanos6/default.nix { };
    nanos6Git = callPackage ./bsc/nanos6/git.nix { };

    vtk = callPackage ./bsc/vtk/default.nix {
      inherit (self.xorg) libX11 xorgproto libXt;
    };

    dummy = callPackage ./bsc/dummy/default.nix { };

    clangOmpss2Unwrapped = callPackage ./bsc/llvm-ompss2/clang.nix {
      stdenv = self.llvmPackages_10.stdenv;
      enableDebug = false;
    };

    clangOmpss2 = callPackage bsc/llvm-ompss2/default.nix {
      clangOmpss2Unwrapped = self.bsc.clangOmpss2Unwrapped;
    };

    stdenvOmpss2 = self.clangStdenv.override {
      cc = self.bsc.clangOmpss2;
    };

    cpic = callPackage ./bsc/apps/cpic/default.nix {
      stdenv = self.bsc.stdenvOmpss2;
      mpi = self.bsc.mpi;
      tampi = self.bsc.tampi;
    };

    mpptest = callPackage ./bsc/mpptest/default.nix { };

    busybox = self.busybox.override {
      enableStatic = true;
    };

    nixtools = callPackage ./bsc/nixtools/default.nix {
      targetCluster = "mn4";
      nixPrefix = "/gpfs/projects/bsc15/nix";
    };

    garlic = {

      # Load some helper functions to generate app variants
      inherit (import ./garlic/gen.nix) genApps genApp genConfigs;

      # Override the hardening flags and parallel build by default (TODO)
      #mkDerivation = callPackage ./garlic/mkDerivation.nix { };

      # Apps for Garlic
#      heat = callPackage ./garlic/heat {
#        stdenv = pkgs.gcc7Stdenv;
#        mpi = intel-mpi;
#        tampi = tampi;
#      };
#
      creams = callPackage ./garlic/creams {
        gnuDef   = self.gfortran10 ; # Default GNU   compiler version
        intelDef = self.bsc.icc    ; # Default Intel compiler version

        gitBranch = "garlic/mpi+send+seq";

        cc  = self.bsc.icc; # self.bsc.icc OR self.gfortran10;
        mpi = self.bsc.mpi; # self.bsc.mpi OR self.bsc.openmpi-mn4;
      };

      creamsInput = callPackage ./garlic/creams/input.nix {
        gitBranch = "garlic/mpi+send+seq";
      };

#      lulesh = callPackage ./garlic/lulesh {
#        mpi = intel-mpi;
#      };
#
#      hpcg = callPackage ./garlic/hpcg { };
#
#      hpccg = callPackage ./garlic/hpccg { };
#
#      fwi = callPackage ./garlic/fwi { };

      nbody = callPackage ./garlic/nbody {
        cc = self.bsc.icc;
        mpi = self.bsc.mpi;
        tampi = self.bsc.tampi;
        mcxx = self.bsc.mcxx;
        gitBranch = "garlic/seq";
      };

      saiph = callPackage ./garlic/saiph {
        cc = self.bsc.clangOmpss2;
      };

      # Execution wrappers
      runWrappers = {
        sbatch    = callPackage ./garlic/stages/sbatch.nix { };
        srun      = callPackage ./garlic/stages/srun.nix { };
        launch    = callPackage ./garlic/stages/launcher { };
        control   = callPackage ./garlic/stages/control.nix { };
        nixsetup  = callPackage ./garlic/stages/nix-setup.nix { };
        argv      = callPackage ./garlic/stages/argv.nix { };
        statspy   = callPackage ./garlic/stages/statspy.nix { };
        extrae    = callPackage ./garlic/stages/extrae.nix { };
        stagen    = callPackage ./garlic/stages/stagen.nix { };
        perf      = callPackage ./garlic/stages/perf.nix { };
        broom     = callPackage ./garlic/stages/broom.nix { };
        envRecord = callPackage ./garlic/stages/envRecord.nix { };
        valgrind  = callPackage ./garlic/stages/valgrind.nix { };
        isolate   = callPackage ./garlic/stages/isolate { };
        trebuchet = callPackage ./garlic/stages/trebuchet { };
        strace    = callPackage ./garlic/stages/strace.nix { };
        unit      = callPackage ./garlic/stages/unit.nix { };
        experiment= callPackage ./garlic/stages/experiment/default.nix { };
      };

      # Tests (move to bsc ?)
      mpptest = callPackage ./garlic/mpptest { };

      ppong = callPackage ./garlic/ppong {
        mpi = self.bsc.mpi;
      };

      # Post processing tools
      hist = callPackage ./garlic/postprocess/hist { };

      exp = {
        #noise = callPackage ./garlic/exp/noise.nix { };
        nbody = {
          bs = callPackage ./garlic/exp/nbody/bs.nix {
            pkgs = self // self.bsc.garlic;
            nixpkgs = import <nixpkgs>;
            genApp = self.bsc.garlic.genApp;
            genConfigs = self.bsc.garlic.genConfigs;
            runWrappers = self.bsc.garlic.runWrappers;
          };

          tampi = callPackage ./garlic/exp/nbody/tampi.nix {
            pkgs = self // self.bsc.garlic;
            nixpkgs = import <nixpkgs>;
            genApp = self.bsc.garlic.genApp;
            genConfigs = self.bsc.garlic.genConfigs;
            runWrappers = self.bsc.garlic.runWrappers;
          };
#          mpi = callPackage ./bsc/garlic/exp/nbody/mpi.nix { };
        };

        saiph = {
          numcomm = callPackage ./garlic/exp/saiph/numcomm.nix {
            pkgs = self // self.bsc.garlic;
            nixpkgs = import <nixpkgs>;
            genApp = self.bsc.garlic.genApp;
            genConfigs = self.bsc.garlic.genConfigs;
            runWrappers = self.bsc.garlic.runWrappers;
          };
        };

        creams = {
          ss = {
            pure = callPackage ./garlic/exp/creams/ss+pure.nix {
              pkgs = self // self.bsc.garlic;
              nixpkgs = import <nixpkgs>;
              genApp = self.bsc.garlic.genApp;
              genConfigs = self.bsc.garlic.genConfigs;
              runWrappers = self.bsc.garlic.runWrappers;
            };
            hybrid = callPackage ./garlic/exp/creams/ss+hybrid.nix {
              pkgs = self // self.bsc.garlic;
              nixpkgs = import <nixpkgs>;
              genApp = self.bsc.garlic.genApp;
              genConfigs = self.bsc.garlic.genConfigs;
              runWrappers = self.bsc.garlic.runWrappers;
            };
          };
        };

        osu = rec {
          latency-internode = callPackage ./garlic/exp/osu/latency.nix { };
          latency-intranode = callPackage ./garlic/exp/osu/latency.nix {
            interNode = false;
          };
          latency = latency-internode;
        };

        test = {
          rw = callPackage ./garlic/exp/test/rw.nix {
            pkgs = self // self.bsc.garlic;
            nixpkgs = import <nixpkgs>;
            genApp = self.bsc.garlic.genApp;
            genConfigs = self.bsc.garlic.genConfigs;
            runWrappers = self.bsc.garlic.runWrappers;
          };
#          mpi = callPackage ./bsc/garlic/exp/nbody/mpi.nix { };
        };
      };
    };
  };

in
  {
    bsc = bsc;

    # Alias
    garlic = bsc.garlic;

    # Alias
    exp = bsc.garlic.exp;
  }
