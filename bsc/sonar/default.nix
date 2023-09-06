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
    rev = "1299731b56addc18f530f7327f62267624c4363a";
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
