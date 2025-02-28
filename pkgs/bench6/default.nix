{
  stdenv
, cmake
, clangOmpss2
, nanos6
, nodes
, mpi
, tampi
, gitBranch ? "master"
, gitURL ? "ssh://git@bscpm04.bsc.es/rarias/bench6.git"
, gitCommit ? "1e6ce2aa8ad7b4eef38df1581d7ec48a8815f85d"
}:

stdenv.mkDerivation rec {
  pname = "bench6";
  version = "${src.shortRev}";

  src = builtins.fetchGit {
    url = gitURL;
    ref = gitBranch;
    rev = gitCommit;
  };

  buildInputs = [ cmake clangOmpss2 nanos6 nodes mpi tampi ];

  enableParallelBuilding = false;
  cmakeFlags = [
    "-DCMAKE_C_COMPILER=clang"
    "-DCMAKE_CXX_COMPILER=clang++"
  ];
  hardeningDisable = [ "all" ];
  dontStrip = true;
}
