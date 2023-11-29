{
  stdenv
, fetchFromGitHub
, automake
, autoconf
, libtool
, gnumake
, boost
, mpi
, gcc
, autoreconfHook
, useGit ? false
, gitUrl ? "ssh://git@bscpm03.bsc.es/interoperability/tampi.git"
, gitBranch ? "master"
, gitCommit ? "16f92094ca6da25e2f561c000f5fbc2901944f7b"
}:

let
  release = rec {
    version = "3.0";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "tampi";
      rev = "v${version}";
      hash = "sha256-qdWBxPsXKM428F2ojt2B6/0ZsQyGzEiojNaqbhDmrks=";
    };
  };
  git = rec {
    version = src.shortRev;
    src = builtins.fetchGit {
      url = gitUrl;
      ref = gitBranch;
      rev = gitCommit;
    };
  };
  source = if (useGit) then git else release;
in stdenv.mkDerivation rec {
  pname = "tampi";
  inherit (source) src version;
  enableParallelBuilding = true;
  separateDebugInfo = true;
  buildInputs = [
    autoreconfHook
    automake
    autoconf
    libtool
    gnumake
    boost
    mpi
    gcc
  ];
  dontDisableStatic = true;
  hardeningDisable = [ "all" ];
}
