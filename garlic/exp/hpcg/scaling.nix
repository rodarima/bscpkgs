{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, callPackage
, enableExtended ? false
, enableStrong ? true
}:

with lib;
with garlicTools;

let
  common = callPackage ./common.nix { };

  inherit (common) pipeline getSizePerTask;

  maxNodes = 16;

  # Initial variable configuration
  varConf = {
    nodes = range2 1 maxNodes;
    baseSizeZ = if (enableExtended) then [ 8 16 ] else [ 16 ];
    blocksPerCpu = if (enableExtended) then range2 1 8 else [ 4 ];
    gitBranch = [
      "garlic/tampi+isend+oss+task"
    ];
  };

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    expName = if (enableStrong) then "hpcg-ss" else "hpcg-ws";
    unitName = "${expName}"
    + "-nodes${toString nodes}"
    + "-bpc${toString blocksPerCpu}";

    inherit (targetMachine.config) hw;

    inherit maxNodes;
    sizeFactor = if (enableStrong) then maxNodes / nodes else 1;
    
    # hpcg options
    inherit (c) nodes blocksPerCpu gitBranch;
    totalTasks = ntasksPerNode * nodes;
    sizePerCpu = {
      x = 2;
      y = 2;
      z = c.baseSizeZ * sizeFactor;
    };
    sizePerTask = getSizePerTask cpusPerTask sizePerCpu;
    nprocs = { x=1; y=1; z=totalTasks; };
    nblocks = blocksPerCpu * cpusPerTask;
    ncomms = 1;
    disableAspectRatio = true;

    # Repeat the execution of each unit several times
    loops = 10;

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
