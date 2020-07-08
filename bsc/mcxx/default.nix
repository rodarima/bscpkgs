{ stdenv
, fetchgit
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
  name = "mcxx";
  #version attribute ignored when using fetchgit:
  #version = "2.2.0-70a299cf";

  # Use patched Extrae version
  src = fetchgit {
    url = "https://github.com/bsc-pm/mcxx";
    rev = "70a299cfeb1f96735e6b9835aee946451f1913b2";
    sha256 = "1n8y0h47jm2ll67xbz930372xkl9647z12lfwz2472j3y86yxpmw";
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

  configureFlags = [
    "--enable-ompss-2"
    "--with-nanos6=${nanos6}"
  ];
    
}
