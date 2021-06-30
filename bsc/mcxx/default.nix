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
  version = "2.2.98+da8945d0";

  passthru = {
    CC = "mcc";
    CXX = "mcxx";
  };

  # mcxx doesn't use tags, so we pick the same version of the ompss2 release
  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = pname;
    rev = "ae79b93090a104f2cd30faae00389dac8318a7c9";
    sha256 = "1nwz0v63nvsp0d3qgvv8kpaqcisqk0m7360wy7fhy3xc8n3n3mas";
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
