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
  name = "mcxx-rarias";
  #version attribute ignored when using fetchgit:
  #version = "2.2.0-70a299cf";

  #src = /home/Computational/rarias/mcxx;
  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/rarias/mcxx";
    rev = "44129a6ac05b8f78b06e9e2eff71438b5ca4d29f";
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
  ];

  # Regenerate ia32 builtins to add the ones for gcc9
  #preBuild = ''
  #  make generate_builtins_ia32 GXX_X86_BUILTINS=${gcc}/bin/g++
  #'';
}
