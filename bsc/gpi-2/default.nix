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
    ref = "lowlevel";
  };

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
