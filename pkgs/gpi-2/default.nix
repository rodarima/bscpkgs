{
  stdenv
, slurm
, rdma-core
, autoconf
, automake
, libtool
, mpi
, rsync
, gfortran
}:

stdenv.mkDerivation rec {
  pname = "GPI-2";
  version = src.shortRev;

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/interoperability/GPI-2";
    ref = "refs/tags/tagaspi-2021.11";
    rev = "9082fe7770fa9f6acba1b1ac938ad209a3d09477";
  };

  enableParallelBuilding = true;

  preConfigure = ''
    patchShebangs autogen.sh
    ./autogen.sh
  '';

  configureFlags = [
    "--with-infiniband=${rdma-core}"
    "--with-mpi=${mpi}"
    "--with-slurm"
    "CFLAGS=-fPIC"
    "CXXFLAGS=-fPIC"
  ];

  buildInputs = [ slurm mpi rdma-core autoconf automake libtool rsync gfortran ];

  hardeningDisable = [ "all" ];
}
