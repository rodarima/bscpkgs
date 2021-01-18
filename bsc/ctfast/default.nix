{
  stdenv
, babeltrace2
, pkg-config
, uthash
}:

stdenv.mkDerivation rec {
  pname = "ctfast";
  version = "${src.shortRev}";

  buildInputs = [
    babeltrace2
    pkg-config
    uthash
  ];

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/rarias/ctfast.git";
    ref = "master";
  };

  # Fix the search path
  configurePhase = ''
    sed -i "s@^CTFPLUGINS=.*@CTFPLUGINS=$out/lib/nanos6@" ctfast2prv
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ctfast2prv $out/bin

    mkdir -p $out/lib/nanos6
    cp prv.so $out/lib/nanos6/
  '';
}
