{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.lib) callPackageWith;
  inherit (pkgs.lib) callPackagesWith;
  callPackage = callPackageWith (pkgs // self.bsc);
  callPackages = callPackagesWith (pkgs // self.bsc);

  self.bsc = rec {

    # Load the default implementation
    #mpi = pkgs.mpich;
    #mpi = pkgs.openmpi;
    mpi = openmpi; # Our OpenMPI variant
    #mpi = intel-mpi;

    # Load the default compiler
    #stdenv = pkgs.gcc10Stdenv;
    #stdenv = pkgs.gcc9Stdenv;
    #stdenv = pkgs.gcc7Stdenv;
    stdenv = pkgs.llvmPackages_10.stdenv;
    #stdenv = pkgs.llvmPackages_9.stdenv;
    #stdenv = pkgs.llvmPackages_8.stdenv;
    #stdenv = pkgs.llvmPackages_7.stdenv;

    binutils = pkgs.binutils;
    coreutils = pkgs.coreutils;

    # --------------------------------------------------------- #
    #  BSC Packages
    # --------------------------------------------------------- #

    # Custom OpenMPI with mpi_cxx enabled for TAMPI
    openmpi = callPackage ./bsc/openmpi/default.nix {
      enableCxx = true;
    };

    intel-mpi-2019 = callPackage ./bsc/intel-mpi/default.nix {
      # Intel MPI provides a debug version of the MPI library, but
      # by default we use the release variant for performance
      enableDebug = false;
    };

    # Default Intel MPI version is 2019 (the last one)
    intel-mpi = intel-mpi-2019;

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
      stdenv = pkgs.gcc9Stdenv;
      nanos6 = nanos6-git;
    };

    nanos6 = callPackage ./bsc/nanos6/default.nix {
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
    };

    clang-ompss2 = callPackage bsc/llvm-ompss2/default.nix {
      nanos6 = nanos6-git;
      inherit clang-ompss2-unwrapped;
    };

    stdenv-nanos6 = pkgs.clangStdenv.override {
      cc = clang-ompss2;
    };

    cpic = callPackage ./bsc/apps/cpic/default.nix {
      stdenv = stdenv-nanos6;
      nanos6 = nanos6-git;
      inherit mpi tampi;
    };

    # Apps for Garlic
    nbody = callPackage ./bsc/apps/nbody/default.nix {
      stdenv = pkgs.gcc9Stdenv;
      mpi = intel-mpi;
      tampi = tampi;
      nanos6 = nanos6-git;
    };

    saiph = callPackage ./bsc/apps/saiph/default.nix {
      stdenv = stdenv-nanos6;
      mpi = intel-mpi;
      tampi = tampi;
      nanos6 = nanos6-git;
      inherit vtk;
      boost = pkgs.boost;
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

    test = {
      chroot = callPackage ./test/chroot.nix { };

      internet = callPackage ./test/security/internet.nix { };

      clang-ompss2 = callPackage ./test/compilers/clang-ompss2.nix {
        stdenv = stdenv-nanos6;
        nanos6 = nanos6-git;
        inherit clang-ompss2;
      };
    };
  };

in pkgs // self
