{
  pkgs
, bsc
}:

let
  callPackage = pkgs.lib.callPackageWith (pkgs // bsc // garlic);
  callPackages = pkgs.lib.callPackagesWith (pkgs // bsc // garlic);

  # Load some helper functions to generate app variants
  inherit (import ./gen.nix) genApps genConfigs;

  garlic = rec {

    mpptest = callPackage ./mpptest { };

    ppong = callPackage ./ppong { };

    exp = {
      mpiImpl = callPackage ./experiments {
        apps = genApps [ ppong ] (
          genConfigs {
            mpi = [ bsc.intel-mpi pkgs.mpich pkgs.openmpi ];
          }
        );
      };
    };
  };

in
  garlic
