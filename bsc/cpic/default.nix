{
  stdenv
, libconfig
, nanos6
, mpi
, uthash
, overrideCC
, llvmPackages_10
, fftw
, tampi
, hdf5
, libgcc
, strace
, gcc
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
    env | grep NIX
  '';


  preConfigure = ''
    export NANOS6_HOME="${nanos6}"
  '';

  #enableParallelBuilding = true;

  buildInputs = [
    libconfig
    nanos6
    mpi
    uthash
#    llvmPackages_10.bintools
    fftw
#    tampi
    hdf5
    libgcc
    strace
    gcc
  ];

# Doesnt work
#    export LIBRARY_PATH=${libgcc}/lib
#    export LD_LIBRARY_PATH=${libgcc}/lib
#  buildPhase = ''
#    #NIX_DEBUG=5 strace -ff -s99999 -e trace=execve make SHELL='bash -x'
#    NIX_DEBUG=5 strace -ff -s99999 -e trace=execve make SHELL='bash -x'
#  '';

  installPhase = ''
    mkdir -p $out/bin
    cp cpic $out/bin/cpic
  '';
}
