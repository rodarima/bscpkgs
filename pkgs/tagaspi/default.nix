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
    ref = "refs/tags/2021.11";
    rev = "5aabb1849de2e512cc8729f32783051ecd4cab97";
  };

  hardeningDisable = [ "all" ];
}
