{
  stdenv
, cc
, mpi
}:

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "shuffle";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/dalvare1/bigsort.git";
    ref = "garlic/mpi+send+omp+task";
  };

  postUnpack = "sourceRoot=$sourceRoot/ShuffleSeq";

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
    "I_MPI_CXX=${cc.CXX}"
    "CPP_BIN=mpicxx"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin
    cp shuffle $out/bin/shuffle
  '';

  programPath = "/bin/shuffle";
}
