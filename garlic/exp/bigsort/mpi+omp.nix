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
    n = [ 1024 ];
    bs = [ 256 ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "bigsort.mpi+omp";
    unitName = "${expName}.bs${toString bs}";

    # hpcg options
    n = c.n;
    bs = c.bs;
    cc = bsc.icc;
    mpi = bsc.mpi; # TODO: Remove this for oss
    gitBranch = "garlic/mpi+send+omp+task";

    # Repeat the execution of each unit 30 times
    loops = 1;

    # Resources
    qos = "debug";
    ntasksPerNode = 1;
    nodes = 1;
    time = "01:00:00";
    # task in one socket
    cpuBind = "verbose,mask_cpu:0xffffff";
    jobName = "bigsort-${toString n}-${toString bs}-${gitBranch}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  # input = genInput configs;

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    #env = "NANOS6_DEPENDENCIES=discrete";
    argv = [
      "${toString n}"
      "${toString bs}"
      "test"
      "test2"
      #"${toString inputFile}"
      #"${toString outputFile}"
      "$TMPDIR"
      "${toString (builtins.div bs 2)}"
    ];
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.bigsort.override {
      inherit cc gitBranch;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  #{ inherit configs pipeline; }
  stdexp.genExperiment { inherit configs pipeline; }
