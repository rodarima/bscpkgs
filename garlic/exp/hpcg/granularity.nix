{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, callPackage
}:

with stdenv.lib;
with garlicTools;

let
  common = callPackage ./common.nix { };

  inherit (common) pipeline getSizePerTask;

  maxNodes = 16;

  # Initial variable configuration
  varConf = {
    blocksPerCpu = range2 0.5 256;
    gitBranch = [
      "garlic/tampi+isend+oss+task"
    ];
  };

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    expName = "hpcg-granularity";
    unitName = "${expName}"
    + "-nodes${toString nodes}"
    + "-bpc${toString blocksPerCpu}";

    inherit (targetMachine.config) hw;

    inherit maxNodes;
    sizeFactor = maxNodes / nodes;
    
    # hpcg options
    inherit (c) blocksPerCpu gitBranch;
    baseSizeZ = 16;
    nodes = 1;
    totalTasks = ntasksPerNode * nodes;
    sizePerCpu = {
      x = 2;
      y = 2;
      z = baseSizeZ * sizeFactor;
    };
    sizePerTask = getSizePerTask cpusPerTask sizePerCpu;
    nprocs = { x=1; y=1; z=totalTasks; };
    nblocks = floatTruncate (blocksPerCpu * cpusPerTask);
    ncomms = 1;
    disableAspectRatio = true;

    # Repeat the execution of each unit several times
    loops = 3;

    # Resources
    qos = "debug";
    time = "02:00:00";
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = hw.socketsPerNode;
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

in

  stdexp.genExperiment { inherit configs pipeline; }
