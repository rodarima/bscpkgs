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
    blocksize = [ 128 ];
    nodes = range2 1 16;
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

    inherit (c) blocksize nodes gitBranch;

    expName = "nbody-scaling";
    unitName = expName +
      "-${toString gitBranch}" +
      "-nodes${toString nodes}";

    loops = 5;

    qos = "debug";
    ntasksPerNode = hw.socketsPerNode;
    time = "02:00:00";
    cpusPerTask = hw.cpusPerSocket;
    jobName = unitName;
  };

  common = callPackage ./common.nix {};

  inherit (common) getConfigs pipeline;

  configs = getConfigs {
    inherit varConf genConf;
  };

in

  stdexp.genExperiment { inherit configs pipeline; }
