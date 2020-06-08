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
    mpi = pkgs.mpich;

    extrae = callPackage ./bsc/extrae {
    };

    tampi = callPackage ./bsc/tampi {
      mpi = mpi;
    };

    nanos6 = callPackage ./bsc/nanos6 { };
};
in pkgs // self
