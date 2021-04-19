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

  # Initial variable configuration
  varConf = {
    sizeFactor = [ 1 2 4 8 16 32 ];
  };

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    expName = "hpcg-size";
    unitName = "${expName}"
    + "-nodes${toString nodes}"
    + "-sf${toString sizeFactor}";

    inherit (targetMachine.config) hw;

    # hpcg options
    inherit (c) sizeFactor;
    gitBranch = "garlic/tampi+isend+oss+task";
    nodes = 16;
    totalTasks = ntasksPerNode * nodes;
    sizePerCpu = { x = 2; y = 2; z = 4 * sizeFactor; };
    sizePerTask = getSizePerTask cpusPerTask sizePerCpu;
    nprocs = { x=1; y=1; z=totalTasks; };
    blocksPerCpu = 4;
    nblocks = blocksPerCpu * cpusPerTask;
    ncomms = 1;
    disableAspectRatio = true;

    # Repeat the execution of each unit several times
    loops = 5;

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
