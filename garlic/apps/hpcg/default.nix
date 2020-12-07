{
  stdenv
, cc
, nanos6 ? null
, mcxx ? null
, mpi ? null
, gitBranch
}:

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "hpcg";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/rpenacob/garlic-hpcg.git";
    ref = "${gitBranch}";
  };

  prePatch = ''
    #export NIX_DEBUG=6
  '';

  buildInputs = [
    cc
  ]
  ++ optional (mcxx != null) mcxx
  ++ optional (nanos6 != null) nanos6
  ++ optional (mpi != null) mpi;

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
