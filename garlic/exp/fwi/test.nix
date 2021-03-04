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
  varConf = {
    gitBranch = [
      "garlic/tampi+send+oss+task"
#      "garlic/mpi+send+omp+task"
#      "garlic/mpi+send+oss+task"
#      "garlic/mpi+send+seq"
#      "garlic/oss+task"
#      "garlic/omp+task"
#      "garlic/seq"
    ];

    blocksize = [ 1 2 4 ];
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "fwi";
    unitName = "${expName}-test";
    inherit (machineConfig) hw;

    cc = icc;
    inherit (c) gitBranch blocksize;
    n = 500;
    nx = n;
    ny = n;
    nz = n;

    # Repeat the execution of each unit several times
    loops = 10;

    # Resources
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = 1;
    nodes = 1;
    qos = "debug";
    time = "02:00:00";
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}:
  let
    input = bsc.apps.fwi.input.override {
      inherit (conf) nx ny nz;
    };
  in stages.exec {
    inherit nextStage;
    pre = ''
      ln -fs ${input}/InputModels InputModels || true
    '';
    argv = [
      "${input}/fwi_params.txt"
      "${input}/fwi_frequencies.txt"
      conf.blocksize
      "-1" # Fordward steps
      "-1" # Backward steps
      "-1" # Write/read frequency
    ];
  };

  apps = bsc.garlic.apps;

  # FWI program
  program = {nextStage, conf, ...}: apps.fwi.solver.override {
    inherit (conf) cc gitBranch;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
