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

  dontUnpack = true;

  buildPhase = ''
    pwd
    ls -la
    mpicc PPong.c -o ppong
  '';

  buildInputs = [ mpi ];
}
