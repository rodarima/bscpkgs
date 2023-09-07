{
  stdenv
, cmake
, clangOmpss2Git
, nanos6Git
, nodes
, mpi
, tampiGit
, gitBranch ? "master"
, gitURL ? "ssh://git@bscpm03.bsc.es/rarias/bench6.git"
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

  buildInputs = [ cmake clangOmpss2Git nanos6Git nodes mpi tampiGit ];

  enableParallelBuilding = false;
  cmakeFlags = [
    "-DCMAKE_C_COMPILER=clang"
    "-DCMAKE_CXX_COMPILER=clang++"
  ];
  hardeningDisable = [ "all" ];
  dontStrip = true;
}
