{
  stdenv
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
  version = src.shortRev;
  enableParallelBuilding = true;

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

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/interoperability/tagaspi";
    ref = "master";
  };

  hardeningDisable = [ "all" ];
}
