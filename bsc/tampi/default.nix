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
  version = "1.0.2";
  pname = "tampi";
  enableParallelBuilding = true;
  buildInputs = [ autoreconfHook automake autoconf libtool gnumake boost mpi gcc ];
  dontDisableStatic = true;

  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "tampi";
    rev = "v${version}";
    sha256 = "09711av3qbah56mchr81679x05zxl3hi0pjndcnvk7jsfcdxvbm7";
  };
}
