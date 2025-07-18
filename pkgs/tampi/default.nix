{
  stdenv
, lib
, fetchFromGitHub
, automake
, autoconf
, libtool
, gnumake
, boost
, mpi
, gcc
, autoreconfHook
, enableOvni ? true
, ovni ? null
, useGit ? false
, gitUrl ? "ssh://git@bscpm04.bsc.es/interoperability/tampi.git"
, gitBranch ? "master"
, gitCommit ? "f6455db9d3124ae36e715a4874fd49720e79f20a"
}:

with lib;

assert enableOvni -> (ovni != null);

let
  release = rec {
    version = "4.1";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "tampi";
      rev = "v${version}";
      hash = "sha256-SwfPSnwcZnRnSgNvCD5sFSUJRpWINqI5I4adj5Hh+XY=";
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
  ] ++ optional (enableOvni) ovni;
  configureFlags = optional (enableOvni) "--with-ovni=${ovni}";
  dontDisableStatic = true;
  hardeningDisable = [ "all" ];
}
