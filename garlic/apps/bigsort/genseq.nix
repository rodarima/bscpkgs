{
  stdenv
, cc
, mpi
}:

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "genseq";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/dalvare1/bigsort.git";
    ref = "garlic/mpi+send+omp+task";
  };

  postUnpack = "sourceRoot=$sourceRoot/GenSeq";

  # FIXME: Remove the ../commons/Makefile as is not useful here, we only need
  # the CPP_SRC and OBJ variables.
  postPatch = ''
    sed -i '1cCPP_SRC = $(wildcard *.cpp)' Makefile
    sed -i '2cOBJ = $(CPP_SRC:.cpp=.o)' Makefile
  '';

  buildInputs = [
    cc
    mpi
  ];

  makeFlags = [
    "I_MPI_CXX=${cc.cc.CXX}"
    "CPP_BIN=mpicxx"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin
    cp genseq $out/bin/genseq
  '';

  programPath = "/bin/genseq";
}
