{
  stdenv
, nanos6
, mpi
, openmpi
, impi
, tampi
, mcxx
, gnuDef
, intelDef
, cc
, gitBranch
}:

assert (mpi == impi || mpi == openmpi);

let
  mpiName = (if mpi == openmpi then
    "OpenMPI"
  else
    "IntelMPI");

  compName = (if cc == intelDef then
    "Intel"
  else
    "GNU");

in
stdenv.mkDerivation rec {
  name = "creams";

  # src = /home/Computational/pmartin1/creams-simplified;
  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/pmartin1/creams-simplified.git";
    ref = "${gitBranch}";
  };

  programPath = "/bin/creams.exe";

  buildInputs = [
    nanos6
    mpi
    cc
    tampi
    mcxx
  ];

  hardeningDisable = [ "all" ];

  configurePhase = ''
    export TAMPI_HOME=${tampi}

    . etc/bashrc

    export FORTRAN_COMPILER=${compName}
    export MPI_LIB=${mpiName}

    echo

    CREAMS_UPDATE_ENVIRONMENT
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -a build/* $out/bin
  '';
}
