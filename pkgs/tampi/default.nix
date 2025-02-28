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
, gitCommit ? "a5c93bf8ab045b71ad4a8d5e2c991ce774db5cbc"
}:

with lib;

assert enableOvni -> (ovni != null);

let
  release = rec {
    version = "4.0";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "tampi";
      rev = "v${version}";
      hash = "sha256-R7ew5tsrxGReTvOeeZe1FD0oThBhOHoDGv6Mo2sbmDg=";
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
