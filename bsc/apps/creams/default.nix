{
  stdenv
, nanos6
, mpi
, tampi
, mcxx
, icc
, strace
}:

stdenv.mkDerivation rec {
  name = "creams";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/pmartin1/creams-simplified.git";
    ref = "MPI+OmpSs-2+TAMPI";
  };

  buildInputs = [
    nanos6
    mpi
    icc
    tampi
    mcxx
    strace
  ];

  hardeningDisable = [ "all" ];

  preBuild = ''
    #export NIX_DEBUG=6
    export TAMPI_HOME=${tampi}
    . etc/bashrc
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -a build/* $out/bin
  '';

}
