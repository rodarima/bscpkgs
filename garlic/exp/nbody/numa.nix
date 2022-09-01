{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, numactl
, callPackage
}:

with lib;
with garlicTools;

let
  # Initial variable configuration
  varConf = {
    blocksize = range2 256 1024;
    gitBranch = [ "garlic/tampi+send+oss+task" ];
    attachToSocket = [ true false ];
    interleaveMem = [ true false ];
  };

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    hw = targetMachine.config.hw;
    particles = 4 * 1024 * hw.cpusPerSocket;
    timesteps = 10;

    inherit (c) attachToSocket interleaveMem gitBranch blocksize;

    expName = "nbody-numa";
    unitName = expName +
      "-${toString gitBranch}" +
      "-bs.${toString blocksize}" +
      "-tpn.${toString ntasksPerNode}" +
      "-interleave.${if (interleaveMem) then "yes" else "no"}";

    loops = 10;

    qos = "debug";
    cpusPerTask = if (attachToSocket)
      then hw.cpusPerSocket
      else hw.cpusPerNode;
    ntasksPerNode = if (attachToSocket)
      then hw.socketsPerNode
      else 1;
    nodes = 4;
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
