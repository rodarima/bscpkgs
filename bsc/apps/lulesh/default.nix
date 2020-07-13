{
  stdenv
, mpi
, mcxx
, icc
}:

stdenv.mkDerivation rec {
  name = "lulesh";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/mmaronas/lulesh.git";
    ref = "master";
  };

  dontConfigure = true;

  buildInputs = [
    mpi
    icc
    mcxx
  ];

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin
    find . -name 'lulesh*' -type f -executable -exec cp \{\} $out/bin/ \;
  '';

}
