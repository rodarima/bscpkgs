{
  stdenv
, glibc
}:

stdenv.mkDerivation rec {
  pname = "nixtools";
  version = "${src.shortRev}";
  src = builtins.fetchGit {
    url = "ssh://git@bscpm04.bsc.es/rarias/nixtools";
    ref = "master";
    rev = "a103e392048ace3ed88ce74648b32c9e6ed094da";
  };
  buildInputs = [ glibc.static ];
  makeFlags = [ "DESTDIR=$(out)" ];
  preBuild = "env";
  dontPatchShebangs = true;
}
