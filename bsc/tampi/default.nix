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
  version = "1.0.2+6b11368e";
  pname = "tampi";
  enableParallelBuilding = true;
  buildInputs = [ autoreconfHook automake autoconf libtool gnumake boost mpi gcc ];
  dontDisableStatic = true;

  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "tampi";
    rev = "6b11368ea522cd7095cfcf163831b8285faeee7e";
    sha256 = "0519lb1rinhzkk0iy5cjjiqnk1bzhnnzhfigj9ac2c3wl0zcsrvy";
  };

  hardeningDisable = [ "all" ];
}
