{
  stdenv
, cc
, nanos6
, mcxx
, mpi
, tampi
, gitBranch
}:

stdenv.mkDerivation rec {
  name = "hpcg";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/rpenacob/garlic-hpcg.git";
    ref = "${gitBranch}";
  };

  # prePatch = ''
  #   #export NIX_DEBUG=6
  # '';

  buildInputs = [
    cc nanos6 mcxx mpi tampi
  ];

  makeFlags = [
    "CC=${cc.CC}"
    "CXX=${cc.CXX}"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin
    cp bin/* $out/bin/
  '';

  programPath = "/bin/xhpcg";

}
