{
  stdenv
, cc
, mpi ? null
, gitBranch
}:

with stdenv.lib;
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
  ]
  ++ optional (mpi != null) mpi;

  makeFlags = [
    "CC=${cc.cc.CC}"
    "CXX=${cc.cc.CXX}"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin
    cp bin/* $out/bin/
  '';

  programPath = "/bin/xhpcg";

}
