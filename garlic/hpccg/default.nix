{
  stdenv
, nanos6
, mpi
, mcxx
, tampi
, icc
}:

stdenv.mkDerivation rec {
  name = "hpccg";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/mmaronas/HPCCG.git";
    ref = "mmaronas-development";
  };

  buildInputs = [
    nanos6
    mpi
    icc
    tampi
    mcxx
  ];

  # The hpccg app fails to compile in parallel. Makefile must be fixed before.
  enableParallelBuilding = false;

  postPatch = ''
    sed -i 's/mpic++/mpiicpc/g' Makefile
    sed -i 's/g++/icpc/g' Makefile
    mkdir obj
  '';

  makeFlags =  [
    "USE_MPI=-DUSING_MPI"
    "TAMPI_HOME=${tampi}"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp test_HPCCG* $out/bin
  '';
}
