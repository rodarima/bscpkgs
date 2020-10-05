{
  stdenv
, fetchurl
, automake
, autoconf
, libtool
, gnumake
, boost
, mpi
, gcc
, autoreconfHook
}:

stdenv.mkDerivation rec {
  pname = "tampi";
  version = "${src.shortRev}";
  enableParallelBuilding = true;
  buildInputs = [ autoreconfHook automake autoconf libtool gnumake boost mpi gcc ];
  dontDisableStatic = true;
  makeFlags = [ "V=1" ];
  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/interoperability/tampi";
    ref = "master";
  };
}
