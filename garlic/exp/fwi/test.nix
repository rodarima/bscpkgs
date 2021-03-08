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

    blocksize = [ 1 2 ];

    n = [
    	{nx=500; ny=500; nz=500;}
    ];
  };

# The c value contains something like:
# {
#   n = { nx=500; ny=500; nz=500; }
#   blocksize = 1;
#   gitBranch = "garlic/tampi+send+oss+task";
# }

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "fwi";
    unitName = "${expName}-test";
    inherit (machineConfig) hw;

    cc = icc;
    inherit (c) gitBranch blocksize;

    n = 500;
    #nx = c.n.nx;
    #ny = c.n.ny;
    #nz = c.n.nz;

    # Same but shorter:
    inherit (c.n) nx ny nz;

    fwiInput = bsc.apps.fwi.input.override {
      inherit (c.n) nx ny nz;
    };

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

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;
    pre = ''
      ln -fs ${conf.fwiInput}/InputModels InputModels || true
    '';
    argv = [
      "${conf.fwiInput}/fwi_params.txt"
      "${conf.fwiInput}/fwi_frequencies.txt"
      conf.blocksize
      "-1" # Fordward steps
      "-1" # Backward steps
      "-1" # Write/read frequency
    ];
  };

  apps = bsc.garlic.apps;

  # FWI program
  program = {nextStage, conf, ...}: apps.fwi.solver.override {
    inherit (conf) cc gitBranch fwiInput;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
