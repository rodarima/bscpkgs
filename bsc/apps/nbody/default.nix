{
  stdenv
, nanos6
, mpi
, tampi
, mcxx
, icc
}:

stdenv.mkDerivation rec {
  name = "nbody";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/benchmarks/ompss-2/nbody-conflict-kevin.git";
    #rev = "a8372abf9fc7cbc2db0778de80512ad4af244c29";
    ref = "master";
  };

  patchPhase = ''
    sed -i 's/gcc/icc/g'  Makefile
    export NIX_DEBUG=6
  '';

  buildInputs = [
    nanos6
    mpi
    icc
    tampi
    mcxx
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp nbody_* $out/bin/
  '';

}
