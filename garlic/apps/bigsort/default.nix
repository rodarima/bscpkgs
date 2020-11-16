{
  stdenv
, cc
, nanos6 ? null
, mcxx ? null
, mpi
, gitBranch
}:

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "bigsort";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/dalvare1/bigsort.git";
    ref = "${gitBranch}";
  };

  #sourceRoot = "./BigSort";

  preBuild = ''
    cd BigSort
    export I_MPI_CXX=${cc.cc.CXX}
  '';

  buildInputs = [
    cc
    mpi
  ]
  ++ optional (mcxx != null) mcxx
  ++ optional (nanos6 != null) nanos6;

  makeFlags = [
    "CC=${cc.cc.CC}"
    "CXX=${cc.cc.CXX}"
    "CPP_BIN=mpicxx"
    "CLUSTER=MareNostrum4"
    "OPENMP=yes"
    "Debug=no"
    "OPENMP_FLAGS=-qopenmp"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin
    cp bigsort $out/bin/BigSort
  '';

  programPath = "/bin/BigSort";
}
