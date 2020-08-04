{
  pkgs
, bsc
}:

let
  callPackage = pkgs.lib.callPackageWith (pkgs // bsc // garlic);
  callPackages = pkgs.lib.callPackagesWith (pkgs // bsc // garlic);

  # Load some helper functions to generate app variants
  inherit (import ./gen.nix) genApps genApp genConfigs;

  garlic = rec {

    mpptest = callPackage ./mpptest { };

    ppong = callPackage ./ppong {
      mpi = bsc.mpi;
    };

    nbody = callPackage ./nbody {
      cc = pkgs.gcc7;
      gitBranch = "garlic/seq";
    };

    srunner = callPackage ./srunner.nix { };

    ppong-job = srunner { app=ppong; };

    exp = {
      jobs = callPackage ./experiments {
        apps = map (app: srunner {app=app;}) (
          genApps [ ppong ] (
            genConfigs {
              mpi = [ bsc.intel-mpi pkgs.mpich pkgs.openmpi ];
            }
          )
        );
      };

      mpiImpl = callPackage ./experiments {
        apps = genApps [ ppong ] (
          genConfigs {
            mpi = [ bsc.intel-mpi pkgs.mpich pkgs.openmpi ];
          }
        );
      };

      nbody = callPackage ./experiments {
        apps = genApp nbody [
          { cc=bsc.icc;
            cflags="-march=core-avx2"; }
          { cc=bsc.clang-ompss2;
            cflags="-O3 -march=core-avx2 -ffast-math -Rpass-analysis=loop-vectorize"; }
        ];
      };

      nbody-blocksize = callPackage ./experiments {
        apps = genApp nbody (
          genConfigs {
            cc = [ bsc.icc ];
            blocksize = [ "1024" "2048" ];
          });
      };

      # Test if there is any difference between intel -march and -xCORE
      # with target avx2.
      march = callPackage ./experiments {
        apps = genApps [ nbody ] (( genConfigs {
            cc = [ bsc.icc ];
            cflags = [ "-march=core-avx2" "-xCORE-AVX2" ];
          }) ++ ( genConfigs {
            cc = [ bsc.clang-ompss2 ];
            cflags = [ "-O3 -march=core-avx2 -Rpass-analysis=loop-vectorize" ];
          }));
      };
    };
  };

in
  garlic
