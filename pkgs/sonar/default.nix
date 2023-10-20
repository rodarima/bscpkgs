{
  stdenv
, autoreconfHook
, fetchFromGitHub
, ovni
, mpi
}:

stdenv.mkDerivation rec {
  pname = "sonar";
  version = "0.2.0";
  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "sonar";
    rev = "${version}";
    sha256 = "sha256-iQSw4PbFk0EALXPHpLBPPQ7U8Ed8fkez1uG9MuF6PJo=";
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
