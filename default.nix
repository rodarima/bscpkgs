{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.lib) callPackageWith;
  inherit (pkgs.lib) callPackagesWith;
  callPackage = callPackageWith (pkgs // self.bsc);
  callPackageStatic = callPackageWith (pkgs.pkgsStatic);
  callPackages = callPackagesWith (pkgs // self.bsc);

  self.bsc = rec {

    nixpkgs = pkgs;


    # Load the default implementation
    #mpi = mpich;
    #mpi = openmpi;
    mpi = intel-mpi;

    # Load the default compiler
    #stdenv = pkgs.gcc10Stdenv;
    stdenv = pkgs.gcc9Stdenv;
    #stdenv = pkgs.gcc7Stdenv;
    #stdenv = pkgs.llvmPackages_10.stdenv;
    #stdenv = pkgs.llvmPackages_9.stdenv;
    #stdenv = pkgs.llvmPackages_8.stdenv;
    #stdenv = pkgs.llvmPackages_7.stdenv;

    binutils = pkgs.binutils;
    coreutils = pkgs.coreutils;
    gcc = stdenv.cc;

    nanos6 = nanos6-git;

    # --------------------------------------------------------- #
    #  BSC Packages
    # --------------------------------------------------------- #

    perf = callPackage ./bsc/perf/default.nix {
      kernel = pkgs.linuxPackages_4_9.kernel;
      systemtap = pkgs.linuxPackages_4_9.systemtap;
    };

    # ParaStation MPI
    pscom = callPackage ./bsc/parastation/pscom.nix { };
    psmpi = callPackage ./bsc/parastation/psmpi.nix { };

    osumb = callPackage ./bsc/osu/default.nix { };

    mpich = callPackage ./bsc/mpich/default.nix { };
    mpichDbg = callPackage ./bsc/mpich/default.nix { enableDebug = true; };

    # Default Intel MPI version is 2019 (the last one)
    impi = intel-mpi;
    intel-mpi = intel-mpi-2019;
    intel-mpi-2019 = callPackage ./bsc/intel-mpi/default.nix {
      # Intel MPI provides a debug version of the MPI library, but
      # by default we use the release variant for performance
      enableDebug = false;
    };

    # By default we use Intel compiler 2020 update 1
    icc-unwrapped = icc2020-unwrapped;
    icc2020-unwrapped = callPackage ./bsc/intel-compiler/icc2020.nix {
      intel-mpi = intel-mpi-2019;
    };

    # A wrapper script that puts all the flags and environment vars properly and
    # calls the intel compiler binary
    icc = callPackage bsc/intel-compiler/default.nix {
      inherit icc-unwrapped intel-license;
    };

    intel-license = callPackage bsc/intel-compiler/license.nix {
    };

    pmix2 = callPackage ./bsc/pmix/pmix2.nix { };

    slurm17 = callPackage ./bsc/slurm/default.nix {
      pmix = pmix2;
    };

    slurm17-libpmi2 = callPackage ./bsc/slurm/pmi2.nix {
      pmix = pmix2;
    };

    openmpi-mn4 = callPackage ./bsc/openmpi/default.nix {
      pmix = pmix2;
      pmi2 = slurm17-libpmi2;
      enableCxx = true;
    };

    openmpi = openmpi-mn4;

    fftw = callPackage ./bsc/fftw/default.nix {
      mpi = mpi;
    };

    extrae = callPackage ./bsc/extrae/default.nix {
      mpi = mpi;
    };

    tampi = callPackage ./bsc/tampi/default.nix {
      mpi = mpi;
    };

    mcxx = callPackage ./bsc/mcxx/default.nix {
    };

    mcxx-rarias = callPackage ./bsc/mcxx/rarias.nix {
    };

    nanos6-latest = callPackage ./bsc/nanos6/default.nix {
      extrae = extrae;
    };

    nanos6-git = callPackage ./bsc/nanos6/git.nix {
      extrae = extrae;
    };

    vtk = callPackage ./bsc/vtk/default.nix {
      mpi = mpi;
      inherit (pkgs.xorg) libX11 xorgproto libXt;
    };

    dummy = callPackage ./bsc/dummy/default.nix {
    };

    clang-ompss2-unwrapped = callPackage ./bsc/llvm-ompss2/clang.nix {
      stdenv = pkgs.llvmPackages_10.stdenv;
      enableDebug = false;
    };

    clang-ompss2 = callPackage bsc/llvm-ompss2/default.nix {
      inherit clang-ompss2-unwrapped;
    };

    stdenv-nanos6 = pkgs.clangStdenv.override {
      cc = clang-ompss2;
    };

    cpic = callPackage ./bsc/apps/cpic/default.nix {
      stdenv = stdenv-nanos6;
      inherit mpi tampi;
    };

    mpptest = callPackage ./bsc/mpptest/default.nix {
    };

    # Apps for Garlic
    nbody = callPackage ./bsc/apps/nbody/default.nix {
      stdenv = pkgs.gcc9Stdenv;
      mpi = intel-mpi;
      tampi = tampi;
    };

    heat = callPackage ./bsc/apps/heat/default.nix {
      stdenv = pkgs.gcc7Stdenv;
      mpi = intel-mpi;
      tampi = tampi;
    };

    saiph = callPackage ./bsc/apps/saiph/default.nix {
      stdenv = stdenv-nanos6;
      mpi = intel-mpi;
      tampi = tampi;
      inherit vtk;
      boost = pkgs.boost;
    };

    creams = callPackage ./bsc/apps/creams/default.nix {
      stdenv = pkgs.gcc9Stdenv;
      mpi = intel-mpi;
      tampi = tampi.override {
        mpi = intel-mpi;
      };
    };

    lulesh = callPackage ./bsc/apps/lulesh/default.nix {
      mpi = intel-mpi;
    };

    hpcg = callPackage ./bsc/apps/hpcg/default.nix {
    };

    hpccg = callPackage ./bsc/apps/hpccg/default.nix {
    };

    fwi = callPackage ./bsc/apps/fwi/default.nix {
    };

    garlic = callPackage ./bsc/garlic/default.nix {
      pkgs = pkgs;
      bsc = self.bsc;
    };

    # Patched nix for deep cluster
    inherit (callPackage ./bsc/nix/default.nix {
        storeDir = "/nix/store";
        stateDir = "/nix/var";
        boehmgc = pkgs.boehmgc.override { enableLargeConfig = true; };
        })
      nix
      nixUnstable
      nixFlakes;

    clsync = callPackage ./bsc/clsync/default.nix { };

    nixStatic = (callPackageStatic ./bsc/nix/static.nix {
        callPackage = callPackageWith (pkgs.pkgsStatic);
        storeDir = "/nix/store";
        stateDir = "/nix/var";
        sandbox-shell = "/bin/sh";
        boehmgc = pkgs.pkgsStatic.boehmgc.override { enableLargeConfig = true; };
        }).nix;

    test = {
      chroot = callPackage ./test/chroot.nix { };

      internet = callPackage ./test/security/internet.nix { };

      clang-ompss2 = callPackage ./test/compilers/clang-ompss2.nix {
        stdenv = stdenv-nanos6;
        inherit clang-ompss2;
      };
    };
  };

in pkgs // self
