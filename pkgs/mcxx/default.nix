{
  stdenv
, fetchFromGitHub
, autoreconfHook
, nanos6
, gperf
, python3
, gfortran
, pkg-config
, sqlite
, flex
, bison
, gcc
}:

stdenv.mkDerivation rec {
  pname = "mcxx";
  version = "2023.11";

  passthru = {
    CC = "mcc";
    CXX = "mcxx";
  };

  # mcxx doesn't use tags, so we pick the same version of the ompss2 release
  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = pname;
    rev = "github-release-${version}";
    hash = "sha256-GyBvyy/HD3t9rHSXAYZRMhn4o4Nm/HFfjuOS8J0LPu8=";
  };

  enableParallelBuilding = true;

  buildInputs = [
    autoreconfHook
    nanos6
    gperf
    python3
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
