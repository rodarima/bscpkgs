{
  stdenv
, fetchurl
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
  version = "1.0.1";
  name = "tampi-${version}";
  enableParallelBuilding = true;
  buildInputs = [ autoreconfHook automake autoconf libtool gnumake boost mpi gcc ];
  dontDisableStatic = true;
  configureFlags = [ "--disable-mpi-mt-check" "CXXFLAGS=-DOMPI_SKIP_MPICXX=1" ];
  src = fetchurl {
    url = "https://github.com/bsc-pm/tampi/archive/v${version}.tar.gz";
    sha256 = "8608a74325939d2a6b56e82f7f6788efbc67731e2d64793bac69475f5b4b9704";
  };
}
