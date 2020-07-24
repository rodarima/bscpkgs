{
  pkgs
, bsc
}:

let
  callPackage = pkgs.lib.callPackageWith (pkgs // bsc // garlic);
  callPackages = pkgs.lib.callPackagesWith (pkgs // bsc // garlic);
  garlic = rec {

    mpptest = callPackage ./mpptest { };

    ppong = callPackage ./ppong { };

    experiments = callPackage ./experiments {
      apps = [
        (ppong.override { mpi=bsc.intel-mpi;})
        (ppong.override { mpi=pkgs.mpich;})
      ];
    };

  };
in
  garlic
