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
  version = "2.0";
  pname = "tampi";
  enableParallelBuilding = true;
  buildInputs = [ autoreconfHook automake autoconf libtool gnumake boost mpi gcc ];
  dontDisableStatic = true;

  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "tampi";
    rev = "v${version}";
    sha256 = "sha256-m0LDgP4pfUwavUaagcCsZ/ZHbnWBZdtHtGq108btGKM=";
  };

  hardeningDisable = [ "all" ];
}
