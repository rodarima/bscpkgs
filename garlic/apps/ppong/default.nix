{
  stdenv
, mpi
, fetchurl
}:

stdenv.mkDerivation {
  name = "ppong";

  src = fetchurl {
    url = "http://www.csl.mtu.edu/cs4331/common/PPong.c";
    sha256 = "0d1w72gq9627448cb7ykknhgp2wszwd117dlbalbrpf7d0la8yc0";
  };

  unpackCmd = ''
    mkdir src
    cp $src src/ppong.c
  '';

  dontConfigure = true;

  buildPhase = ''
    echo mpicc -include stdlib.h ppong.c -o ppong
    mpicc -include stdlib.h ppong.c -o ppong
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ppong $out/bin/ppong
    ln -s $out/bin/ppong $out/bin/run
  '';

  buildInputs = [ mpi ];
  hardeningDisable = [ "all" ];
}
