{ stdenv
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
  version = "${src.shortRev}";

  passthru = {
    CC = "mcc";
    CXX = "mcxx";
  };

  # Use patched Extrae version
  src = builtins.fetchGit {
    url = "https://github.com/bsc-pm/mcxx";
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

  patches = [ ./intel.patch ];

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
