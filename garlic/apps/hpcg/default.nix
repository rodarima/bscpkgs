{
  stdenv
, cc
, mpi
, gitBranch ? "garlic/seq"
, makefileName ? "Linux_Serial"
}:

stdenv.mkDerivation rec {
  name = "hpcg";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/rpenacob/garlic-hpcg.git";
    ref = "${gitBranch}";
  };

  prePatch = ''
    #export NIX_DEBUG=6
  '';

  buildInputs = [
    cc
    mpi
  ];

  makeFlags = [
    "CC=${cc.cc.CC}"
    "CXX=${cc.cc.CXX}"
  ];

  enableParallelBuilding = true;

  configurePhase = ''
    mkdir build
    cd build
    ../configure ${makefileName}
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bin/* $out/bin/
  '';

}
