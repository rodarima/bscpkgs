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
, symlinkJoin
}:

let
  mpiAll = symlinkJoin {
    name = "mpi-all";
    paths = [ mpi.all ];
  };
in

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
    numactl
    rdma-core
    gfortran
    mpiAll
  ];

  dontDisableStatic = true;

  configureFlags = [
    "--with-gaspi=${gpi-2}"
    "CFLAGS=-fPIC"
    "CXXFLAGS=-fPIC"
  ];

  hardeningDisable = [ "all" ];
}
