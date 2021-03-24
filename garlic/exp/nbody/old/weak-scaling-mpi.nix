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
    numProcs = [ 1 2 4 8 16 32 48 ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    # nbody options
    particles = 1024 * 64;
    timesteps = 10;
    blocksize = 1024;
    inherit (c) numProcs;
    cc = icc;
    mpi = impi;
    gitBranch = "garlic/mpi+send";

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    qos = "debug";
    ntasksPerNode = numProcs;
    nodes = 1;
    time = "02:00:00";
    cpuBind = "sockets,verbose";
    jobName = "nbody-bs-${toString numProcs}-${gitBranch}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    argv = [ "-t" timesteps "-p" particles ];
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.nbody.override {
      inherit cc blocksize mpi gitBranch;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
