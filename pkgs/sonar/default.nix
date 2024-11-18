{
  stdenv
, autoreconfHook
, fetchFromGitHub
, ovni
, mpi
}:

stdenv.mkDerivation rec {
  pname = "sonar";
  version = "1.0.1";
  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "sonar";
    rev = "${version}";
    sha256 = "sha256-DazOEaiMfJLrZNtmQEEHdBkm/m4hq5e0mPEfMtzYqWk=";
  };
  hardeningDisable = [ "all" ];
  dontStrip = true;
  configureFlags = [ "--with-ovni=${ovni}" ];
  buildInputs = [
    autoreconfHook
    ovni
    mpi
  ];
}
