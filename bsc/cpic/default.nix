{
  stdenv
, libconfig
, nanos6
, mpi
, uthash
, fftw
, tampi
, hdf5
}:

stdenv.mkDerivation rec {
  name = "cpic";

  # Use my current cpic version, so I can test changes without commits
  src = /home/Computational/rarias/cpic;

#  src = builtins.fetchGit {
#    url = "https://github.com/rodarima/cpic";
##    rev = "73bd70448587f0925b89e24c8f17e412ea3958e6";
#    ref = "master";
#  };

  postConfigure = ''
    #env
  '';

  preConfigure = ''
    export TAMPI_HOME="${tampi}"
    #export NIX_DEBUG=5
  '';

  enableParallelBuilding = true;
  dontStrip = true;

  buildInputs = [
    libconfig
    nanos6
    mpi
    uthash
    fftw
    tampi
    hdf5
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp cpic $out/bin/cpic
  '';
}
