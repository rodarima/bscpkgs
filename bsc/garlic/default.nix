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

    nbody = callPackage ./nbody {
      cc = pkgs.gcc7;
      gitBranch = "garlic/seq";
    };

    exp = {
      mpiImpl = callPackage ./experiments {
        apps = genApps [ ppong ] (
          genConfigs {
            mpi = [ bsc.intel-mpi pkgs.mpich pkgs.openmpi ];
          }
        );
      };

      nbody = callPackage ./experiments {
        apps = genApps [ nbody ] (
          genConfigs {
            cc = [ pkgs.gcc7 pkgs.gcc9 ];
            gitBranch = [ "garlic/seq" ];
          }
        );
      };

      # Test if there is any difference between intel -march and -xCORE
      # with target avx2.
      march = callPackage ./experiments {
        apps = genApps [ nbody ] (( genConfigs {
            cc = [ bsc.icc ];
            cflags = [ "-march=core-avx2" "-xCORE-AVX2" ];
          }) ++ ( genConfigs {
            cc = [ bsc.clang-ompss2 ];
            cflags = [ "-march=core-avx2 -Rpass-analysis=loop-vectorize" ];
          }));
      };
    };
  };

in
  garlic
