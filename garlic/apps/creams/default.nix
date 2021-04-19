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
, gitBranch ? "garlic/mpi+send+seq"
, gitCommit ? null
, garlicTools
}:

assert (mpi == impi || mpi == openmpi);

let
  # FIXME: We should find a better way to specify the MPI implementation
  # and the compiler.
  mpiName = if mpi == openmpi then "OpenMPI" else "IntelMPI";
  compName = if cc == intelDef then "Intel" else "GNU";

  gitSource = garlicTools.fetchGarlicApp {
    appName = "creams";
    inherit gitCommit gitBranch;
    gitTable = import ./git-table.nix;
  };
in
  stdenv.mkDerivation rec {
    name = "creams";

    inherit (gitSource) src gitBranch gitCommit;

    programPath = "/bin/creams.exe";

    buildInputs = [ nanos6 mpi cc tampi mcxx ];

    hardeningDisable = [ "all" ];

    configurePhase = ''
      export TAMPI_HOME=${tampi}

      . etc/bashrc

      export FORTRAN_COMPILER=${compName}
      export MPI_LIB=${mpiName}

      CREAMS_UPDATE_ENVIRONMENT
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp -a build/* $out/bin
    '';
  }
