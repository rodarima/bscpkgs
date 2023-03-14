{
  stdenv
, clangOmpss2
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

  buildInputs = [ clangOmpss2 ];

  preInstall = ''
    export DESTDIR=$out
  '';

  hardeningDisable = [ "all" ];
  dontStrip = true;
}
