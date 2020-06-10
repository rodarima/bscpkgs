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
    # Load the current implementations
    #mpi = pkgs.mpich;
    mpi = pkgs.openmpi;

    # Load the compiler
    #stdenv = pkgs.gcc7Stdenv;
    #stdenv = pkgs.gcc9Stdenv;
    #stdenv = pkgs.gcc10Stdenv;
    stdenv = pkgs.clangStdenv;

    extrae = callPackage ./bsc/extrae {
      mpi = mpi;
    };

    tampi = callPackage ./bsc/tampi {
      mpi = mpi;
    };

    nanos6 = callPackage ./bsc/nanos6/default.nix {
      extrae = extrae;
    };

    nanos6-git = callPackage ./bsc/nanos6/git.nix {
      extrae = extrae;
    };

    #llvm-ompss2 = callPackage ./bsc/llvm-ompss2 { };
  };
in pkgs // self
