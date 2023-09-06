{
  stdenv
, autoreconfHook
, ovni
, mpi
}:

stdenv.mkDerivation rec {
  pname = "sonar";
  version = src.shortRev;
  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/ovni/sonar";
    ref = "main";
    rev = "1ab3d99d57e1da785bc1addac620b3358c8bbb16";
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
