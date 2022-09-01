# Test FWI variants based on tasks with and without I/O.
# This experiment solves a computationally expensive input which brings the
# storage devices to saturation when I/O is enabled. The same input runs
# without I/O for comparison purposes. Also, a range of block sizes
# deemed as efficient according to the granularity experiment are
# explored.

{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
, callPackage
, enableExtended ? false
}:

with lib;

let
  common = callPackage ./common.nix {};
  inherit (common) getConfigs getResources pipeline;

  inherit (targetMachine) fs;

  # Initial variable configuration
  varConf = {
    gitBranch = [ "garlic/tampi+send+oss+task" ];
    blocksize = [ 1 2 4 8 ];
    n = [ {nx=500; nz=500; ny=16000;} ];
    nodes = if (enableExtended) then range2 1 16 else [ 4 ];
    enableIO = [ false true ];
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    expName = "fwi-io";
    unitName = "${expName}"
    + "-nodes${toString nodes}"
    + "-bs${toString blocksize}"
    + (if (enableIO) then "-io1" else "-io0")
    + "-${toString gitBranch}";

    inherit (machineConfig) hw;
    inherit (c) gitBranch blocksize enableIO nodes;
    inherit (c.n) nx ny nz;

    # Repeat the execution of each unit several times
    loops = 10;

    # Resources
    inherit (getResources { inherit gitBranch hw; })
      cpusPerTask ntasksPerNode;

    qos = "debug";
    time = "02:00:00";
    jobName = unitName;

    enableCTF = false;

    # Enable permissions to write in the local storage
    extraMounts = [ fs.local.temp ];
    tempDir = fs.local.temp;
  };

  configs = getConfigs {
    inherit varConf genConf;
  };

in
 
  stdexp.genExperiment { inherit configs pipeline; }
