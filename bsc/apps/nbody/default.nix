{
  stdenv
, nanos6
, mpi
, tampi
, mcxx
}:

stdenv.mkDerivation rec {
  name = "nbody";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/benchmarks/ompss-2/nbody-conflict-kevin.git";
    #rev = "a8372abf9fc7cbc2db0778de80512ad4af244c29";
    ref = "master";
  };

  dontStrip = true;

  patchPhase = ''
    sed -i 's/mpicc/mpigcc/g'  Makefile
  '';

  buildInputs = [
    nanos6
    mpi
    tampi
    mcxx
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp nbody_* $out/bin/
  '';
}