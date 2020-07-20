{
  stdenv
, nanos6
, mpi
, tampi
, mcxx
, icc
}:

stdenv.mkDerivation rec {
  name = "nbody";

  src = builtins.fetchGit {
    url = "https://gitlab.com/srodrb/BSC-FWI.git";
    ref = "ompss";
  };

  postUnpack = "sourceRoot=$sourceRoot/3_ompss";

  buildInputs = [
    nanos6
    mpi
    icc
    tampi
    mcxx
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp fwi.* $out/bin
    cp ModelGenerator $out/bin
  '';
}
