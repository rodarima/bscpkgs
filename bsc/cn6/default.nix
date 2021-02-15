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

  # Fix the search path
  configurePhase = ''
    sed -i "s@^PRV_LIB_PATH=.*@PRV_LIB_PATH=$out/lib/nanos6@" Makefile
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp cn6 $out/bin

    mkdir -p $out/lib/nanos6
    cp prv.so $out/lib/nanos6/
  '';
}
