{
  stdenv
, automake
, autoconf
, libtool
, mpi
, autoreconfHook
, gaspi
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
    "--with-gaspi=${gaspi}"
    "CFLAGS=-fPIC"
    "CXXFLAGS=-fPIC"
  ];

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/interoperability/tagaspi";
    ref = "master";
  };

  hardeningDisable = [ "all" ];
}
