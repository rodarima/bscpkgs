{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, callPackage
}:

with lib;
with garlicTools;

let
  # Initial variable configuration
  varConf = {
    blocksize = range2 64 2048;
    gitBranch = [
#      "garlic/mpi+send+oss+task" 
#      "garlic/tampi+send+oss+task" 
      "garlic/tampi+isend+oss+task"
    ];
  };

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    hw = targetMachine.config.hw;
    particles = 8 * 1024 * hw.cpusPerSocket;
    timesteps = 10;
    blocksize = c.blocksize;
    gitBranch = c.gitBranch;

    expName = "nbody-granularity";
    unitName = expName +
      "-${toString gitBranch}" +
      "-bs${toString blocksize}";

    loops = 10;

    qos = "debug";
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = hw.socketsPerNode;
    nodes = 1;
    time = "02:00:00";
    jobName = unitName;
  };


  common = callPackage ./common.nix {};

  inherit (common) getConfigs pipeline;

  configs = getConfigs {
    inherit varConf genConf;
  };

in

  stdexp.genExperiment { inherit configs pipeline; }
