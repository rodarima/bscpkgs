{
  stdenv
, clangOmpss2Git
, nanos6Git
, nodes
, mpi
, tampiGit
, gitBranch ? "master"
, gitURL ? "ssh://git@bscpm03.bsc.es/rarias/bench6.git"
}:

stdenv.mkDerivation rec {
  pname = "bench6";
  version = "${src.shortRev}";

  src = builtins.fetchGit {
    url = gitURL;
    ref = gitBranch;
  };

  buildInputs = [ clangOmpss2Git nanos6Git nodes mpi tampiGit ];

  hardeningDisable = [ "all" ];
  dontStrip = true;
}
