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
}:

stdenv.mkDerivation rec {
  version = "3.0";
  pname = "tampi";
  enableParallelBuilding = true;
  separateDebugInfo = true;
  buildInputs = [ autoreconfHook automake autoconf libtool gnumake boost mpi gcc ];
  dontDisableStatic = true;

  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "tampi";
    rev = "v${version}";
    hash = "sha256-qdWBxPsXKM428F2ojt2B6/0ZsQyGzEiojNaqbhDmrks=";
  };

  hardeningDisable = [ "all" ];
}
