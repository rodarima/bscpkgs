{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
}:

with stdenv.lib;

let
  # Initial variable configuration
  varConf = with bsc; {
    numComm = [ 1 2 ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    # saiph options
    devMode = false;
    inherit (c) numComm;
    mpi = impi;
    gitBranch = "garlic/tampi+isend+oss+task+simd";

    # Repeat the execution of each unit 100 times
    loops = 100;

    # Resources
    qos = "debug";
    time = "02:00:00";
    ntasksPerNode = 2;
    nodes = 1;
    cpuBind = "sockets,verbose";
    jobName = "saiph-${toString numComm}-${gitBranch}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
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

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }