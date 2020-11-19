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
  version = "2.3-8e998824";

  passthru = {
    CC = "mcc";
    CXX = "mcxx";
  };

  # mcxx doesn't use tags, so we pick the same version of the ompss2 release
  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = pname;
    rev = "8e998824f0fde001340dbec369ef59e40e53761e";
    sha256 = "0ix20l50m52kcw12a6dhrasgzjjc2y73j55c994sbhyd133n3pln";
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
