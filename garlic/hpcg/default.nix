{
  stdenv
, nanos6
, mpi
, mcxx
, tampi
, icc
}:

stdenv.mkDerivation rec {
  name = "hpcg";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/rpenacob/hpcg.git";
    ref = "symgs_coloring_more_than_one_block_per_task_halos_blocking_discreete";
  };

  prePatch = ''
    #export NIX_DEBUG=6
  '';

  patches = [ ./tampi.patch ];

  buildInputs = [
    nanos6
    mpi
    icc
    tampi
    mcxx
  ];

  enableParallelBuilding = true;

  configurePhase = ''
    export TAMPI_HOME=${tampi}
    mkdir build
    cd build
    ../configure MPI_ICPC_OSS
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bin/* $out/bin/
  '';

}
