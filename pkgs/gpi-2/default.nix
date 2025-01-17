{
  stdenv
, fetchurl
, symlinkJoin
, slurm
, rdma-core
, autoconf
, automake
, libtool
, mpi
, rsync
, gfortran
}:

let
  rdma-core-all = symlinkJoin {
    name ="rdma-core-all";
    paths = [ rdma-core.dev rdma-core.out ];
  };
  mpiAll = symlinkJoin {
    name = "mpi-all";
    paths = [ mpi.all ];
  };
in

stdenv.mkDerivation rec {
  pname = "GPI-2";
  version = "tagaspi-2021.11";

  src = fetchurl {
    url = "https://pm.bsc.es/gitlab/interoperability/extern/GPI-2/-/archive/${version}/GPI-2-${version}.tar.gz";
    hash = "sha256-eY2wpyTpnOXRoAcYoAP82Jq9Q7p5WwDpMj+f1vEX5zw=";
  };

  enableParallelBuilding = true;

  preConfigure = ''
    patchShebangs autogen.sh
    ./autogen.sh
  '';

  configureFlags = [
    "--with-infiniband=${rdma-core-all}"
    "--with-mpi=${mpiAll}"
    "--with-slurm"
    "CFLAGS=-fPIC"
    "CXXFLAGS=-fPIC"
  ];

  buildInputs = [ slurm mpiAll rdma-core-all autoconf automake libtool rsync gfortran ];

  hardeningDisable = [ "all" ];
}
