{
  stdenv
, fetchFromGitHub
, autoreconfHook
, nanos6
, gperf
, python
, gfortran
, pkg-config
, sqlite
, flex
, bison
, gcc
}:

stdenv.mkDerivation rec {
  pname = "mcxx";
  version = src.shortRev;

  passthru = {
    CC = "mcc";
    CXX = "mcxx";
  };

  src = builtins.fetchGit {
    url = "ssh://git@bscpm04.bsc.es/mercurium/mcxx";
    ref = "master";
  };

  enableParallelBuilding = true;

  buildInputs = [
    autoreconfHook
    nanos6
    gperf
    python
    gfortran
    pkg-config
    sqlite.dev
    bison
    flex
    gcc
  ];

  # TODO: Not sure if we need this patch anymore (?)
  #patches = [ ./intel.patch ];

  preConfigure = ''
    export ICC=icc
    export ICPC=icpc
    export IFORT=ifort
  '';

  configureFlags = [
    "--enable-ompss-2"
    "--with-nanos6=${nanos6}"
# Fails with "memory exhausted" with bison 3.7.1
#    "--enable-bison-regeneration"
  ];
}
