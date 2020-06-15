{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.lib) callPackageWith;
  inherit (pkgs.lib) callPackagesWith;
  inherit (pkgs) pythonPackages;
  inherit (pkgs) perlPackages;
  inherit (pkgs) buildPerlPackage;
  callPackage = callPackageWith (pkgs // self.bsc);
  callPackage_i686 = callPackageWith (pkgs.pkgsi686Linux // self.bsc);
  callPackages = callPackagesWith (pkgs // self.bsc);

  self.bsc = rec {

    # Custom OpenMPI with mpi_cxx enabled for TAMPI
    openmpi = callPackage ./bsc/openmpi/default.nix {
      enableCxx = true;
    };

    # Load the default implementation
    #mpi = pkgs.mpich;
    #mpi = pkgs.openmpi;
    mpi = openmpi; # Our OpenMPI variant

    # Load the default compiler
    #stdenv = pkgs.gcc7Stdenv;
    #stdenv = pkgs.gcc9Stdenv;
    #stdenv = pkgs.gcc10Stdenv;
    stdenv = pkgs.clangStdenv;

    binutils = pkgs.binutils;
    coreutils = pkgs.coreutils;

    fftw = callPackage ./bsc/fftw/default.nix {
      mpi = mpi;
    };

    extrae = callPackage ./bsc/extrae/default.nix {
      mpi = mpi;
    };

    tampi = callPackage ./bsc/tampi/default.nix {
      mpi = mpi;
    };

    nanos6 = callPackage ./bsc/nanos6/default.nix {
      extrae = extrae;
    };

    nanos6-git = callPackage ./bsc/nanos6/git.nix {
      extrae = extrae;
    };

    clang-ompss2-unwrapped = callPackage ./bsc/llvm-ompss2/default.nix { };

    clang-ompss2 = import ./bsc/cc-wrapper/default.nix {
#      inherit stdenv binutils coreutils ;
#      stdenv = bsc.stdenv;
      coreutils = pkgs.coreutils;
      bintools = pkgs.binutils;
      gnugrep = pkgs.gnugrep;
      stdenvNoCC = pkgs.stdenvNoCC;
      libc = pkgs.glibc;
      nativeTools = false;
      nativeLibc = false;
      cc = clang-ompss2-unwrapped;
    };

#    gcc = lib.makeOverridable (import ./bsc/cc-wrapper/default.nix) {
#      nativeTools = false;
#      nativeLibc = false;
#      isGNU = true;
#      buildPackages = {
#        inherit (prevStage) stdenv;
#      };
#      cc = prevStage.gcc-unwrapped;
#      bintools = self.binutils;
#      libc = getLibc self;
#      inherit (self) stdenvNoCC coreutils gnugrep;
#      shell = self.bash + "/bin/bash";
#    };

    #stdenv = stdenvClangOmpss;

#    WrappedICC = import ../patches/cc-wrapper  {
#      inherit stdenv binutils coreutils ;
#      libc = glibc;
#      nativeTools = false;
#      nativeLibc = false;
#      cc = icc-native;
#    };
#
#
#    stdenvICC = (overrideCC stdenv WrappedICC) // {  isICC = true; };
#
#    stdenvIntelfSupported = if (WrappedICC != null) then stdenvICC else stdenv;
#
#    stdenvIntelIfSupportedElseClang = if (WrappedICC != null) then stdenvICC else clangStdenv;
#
#    intelMKLIfSupported = if (WrappedICC != null) then intel-mkl else pkgs.blas;
#  };

#    llvmPackages_10 = callPackage ../development/compilers/llvm/10 ({
#      inherit (stdenvAdapters) overrideCC;
#      buildLlvmTools = buildPackages.llvmPackages_10.tools;
#      targetLlvmLibraries = targetPackages.llvmPackages_10.libraries;
#    } // stdenv.lib.optionalAttrs (stdenv.hostPlatform.isi686 && buildPackages.stdenv.cc.isGNU) {
#      stdenv = gcc7Stdenv;
#    });

#    llvmPackages_latest = llvmPackages_10;

    stdenv_nanos6 = pkgs.clangStdenv.override {
      cc = clang-ompss2;
    };

    cpic = callPackage ./bsc/cpic/default.nix {
      stdenv = stdenv_nanos6;
      tampi = tampi;
#      mpi = mpi;
#      nanos6 = nanos6-git;
#      llvm-ompss2 = llvm-ompss2;
    };

    dummy = callPackage ./bsc/dummy/default.nix {
    };

  };
in pkgs // self
