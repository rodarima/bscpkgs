{
  stdenv
, lib
, cmake
, mpi
, gitBranch ? "master"
, gitURL ? "ssh://git@bscpm03.bsc.es/rarias/ovni.git"
, gitCommit ? null
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
