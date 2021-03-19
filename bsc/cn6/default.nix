{
  stdenv
, babeltrace2
, pkg-config
, uthash
}:

stdenv.mkDerivation rec {
  pname = "cn6";
  version = "${src.shortRev}";

  buildInputs = [
    babeltrace2
    pkg-config
    uthash
  ];

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/rarias/cn6.git";
    ref = "master";
  };

  makeFlags = [ "PREFIX=$(out)" ];
}
