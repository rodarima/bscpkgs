{
  stdenv
, fetchFromGitHub
, automake
, autoconf
, libtool
, mpi
, autoreconfHook
, gpi-2
, boost
, numactl
, rdma-core
, gfortran
}:

stdenv.mkDerivation rec {
  pname = "tagaspi";
  enableParallelBuilding = true;
  separateDebugInfo = true;

  version = "2.0";
  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "tagaspi";
    rev = "v${version}";
    hash = "sha256-RGG/Re2uM293HduZfGzKUWioDtwnSYYdfeG9pVrX9EM=";
  };

  buildInputs = [
    autoreconfHook
    automake
    autoconf
    libtool
    boost
    mpi
    numactl
    rdma-core
    gfortran
  ];

  dontDisableStatic = true;

  configureFlags = [
    "--with-gaspi=${gpi-2}"
    "CFLAGS=-fPIC"
    "CXXFLAGS=-fPIC"
  ];

  hardeningDisable = [ "all" ];
}
