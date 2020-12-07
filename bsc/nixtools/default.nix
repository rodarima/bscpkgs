{
  stdenv
, glibc
}:

stdenv.mkDerivation rec {
  pname = "nixtools";
  version = "${src.shortRev}";
  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/rarias/nixtools";
    ref = "master";
  };
  buildInputs = [ glibc.static ];
  makeFlags = [ "DESTDIR=$(out)" ];
  preBuild = "env";
  dontPatchShebangs = true;
}
