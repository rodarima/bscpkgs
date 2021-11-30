{
  stdenv
, lib
, cmake
, mpi
, gitBranch ? "master"
, gitURL ? "ssh://git@gitlab-internal.bsc.es/nos-v/ovni.git"
, gitCommit ? "9c371d8c12ae4aed333bd7f90d0468603163ad6c"
# By default use debug
, enableDebug ? true
}:

with lib;

stdenv.mkDerivation rec {
  pname = "ovni";
  version = "${src.shortRev}";

  buildInputs = [ cmake mpi ];

  cmakeBuildType = if (enableDebug) then "Debug" else "Release";
  dontStrip = true;

  src = builtins.fetchGit ({
    url = gitURL;
    ref = gitBranch;
  } // optionalAttrs (gitCommit != null) ({
    rev = gitCommit;
  }));
}
