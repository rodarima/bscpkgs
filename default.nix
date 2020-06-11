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

    llvm-ompss2 = callPackage ./bsc/llvm-ompss2/default.nix { };

    cpic = callPackage ./bsc/cpic/default.nix {
      mpi = mpi;
      nanos6 = nanos6-git;
      llvm-ompss2 = llvm-ompss2;
    };

    dummy = callPackage ./bsc/dummy/default.nix { };

  };
in pkgs // self
