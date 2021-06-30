{
  stdenv
, fetchFromGitHub
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
  version = "1.1";
  pname = "tampi";
  enableParallelBuilding = true;
  buildInputs = [ autoreconfHook automake autoconf libtool gnumake boost mpi gcc ];
  dontDisableStatic = true;

  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "tampi";
    rev = "v${version}";
    sha256 = "0m369l3kprginqkkdjf5znlbrwvib2vjlhdy63nbvlw6v5ys7sci";
  };

  hardeningDisable = [ "all" ];
}
