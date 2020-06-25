{stdenv, curl, coreutils}:

stdenv.mkDerivation rec {
  version = "0.0.1";
  name = "internet-test";
  src = ./internet.nix;
  dontUnpack = true;
  buildInputs = [ curl coreutils ];
  buildPhase = ''
    cat /proc/self/mounts
    ls -l /proc
    ls -l /
    ip addr
    ${curl}/bin/curl https://www.bsc.es/
  '';

  installPhase = ''
    mkdir -p $out
  '';
}
