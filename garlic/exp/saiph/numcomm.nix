{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
}:

with stdenv.lib;

let
  # Configurations for each unit (using the cartesian product)
  confUnit = with bsc; {
    numComm = [ 1 2 ];
  };

  # Configuration for the complete experiment
  confExperiment = with bsc; {
    # saiph options
    devMode = false;
    mpi = impi;
    gitBranch = "garlic/tampi+isend+oss+task+simd";

    # Repeat the execution of each unit 30 times
    loops = 100;

    # Resources
    ntasksPerNode = 2;
    nodes = 1;
    cpuBind = "sockets,verbose";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    var = confUnit;
    fixed = targetMachine.config // confExperiment;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    env = ''
      export OMP_NUM_THREADS=24
      export NANOS6_REPORT_PREFIX="#"
      export I_MPI_THREAD_SPLIT=1
      export ASAN_SYMBOLIZER_PATH=${bsc.clangOmpss2Unwrapped}/bin/llvm-symbolizer
    '';
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
  customPkgs.apps.saiph.override {
    inherit devMode numComm mpi gitBranch;
  };

  pipeline = stdexp.stdStages ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
