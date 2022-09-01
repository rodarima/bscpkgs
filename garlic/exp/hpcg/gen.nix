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

rec {

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    expName = "hpcg-gen";
    unitName = expName
    + "-nodes${toString nodes}"
    + "-spt.z${toString sizePerTask.z}";

    inherit (targetMachine.config) hw;

    # Inherit options from the current conf
    inherit (c) sizePerTask nprocs disableAspectRatio gitBranch
      cpusPerTask ntasksPerNode nodes;

    # nblocks and ncomms are ignored from c
    ncomms = 1;
    nblocks = 1;

    # We only need one run
    loops = 1;

    # Generate the input
    enableGen = true;

    # Resources
    qos = "debug";
    time = "02:00:00";
    jobName = unitName;
  };

  common = callPackage ./common.nix {};

  getInputTre = conf: stdexp.genExperiment {
    configs = [ (genConf conf) ];
    pipeline = common.pipeline;
  };
}
