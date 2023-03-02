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
  version = "2022.11";

  passthru = {
    CC = "mcc";
    CXX = "mcxx";
  };

  # mcxx doesn't use tags, so we pick the same version of the ompss2 release
  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = pname;
    rev = "github-release-${version}";
    sha256 = "DMT5UPwsjVo2d0r2wgQvYhcrAacOe+BkiXjAvFA0zGo=";
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
