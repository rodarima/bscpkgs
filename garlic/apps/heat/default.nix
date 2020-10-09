{
  stdenv
, nanos6
, mpi
, tampi
, mcxx
, icc
}:

stdenv.mkDerivation rec {
  name = "heat";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/benchmarks/ompss-2/heat-conflict-kevin.git";
    #rev = "25fde23e5ad5f5e2e58418ed269bc2b44642aa17";
    ref = "master";
  };

  buildInputs = [
    nanos6
    mpi
    icc
    tampi
    mcxx
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp heat_* $out/bin/
  '';

}
