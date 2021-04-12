# This experiment compares the effect of not using I/O versus using O_DIRECT |
# O_DSYNC enabled I/O. This is a reduced version of the strong_scaling_io
# experiment.

{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, callPackage
}:

with stdenv.lib;

let
  common = callPackage ./common.nix {};
  inherit (common) getConfigs getResources pipeline;

  inherit (targetMachine) fs;

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

    blocksize = [ 1 ];

    n = [
        {nx=500; nz=500; ny=16000;}
    ];

    nodes = [ 4 ];
    ioFreq = [ 9999 (-1) ];
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "fwi-sync-io";
    unitName = "${expName}"
      + "-ioFreq${toString ioFreq}"
      + "-${toString gitBranch}";

    inherit (machineConfig) hw;
    inherit (c) gitBranch blocksize;
    inherit (c.n) nx ny nz;

    # Other FWI parameters
    ioFreq = c.ioFreq;

    # Repeat the execution of each unit several times
    loops = 10;

    # Resources
    inherit (getResources { inherit gitBranch hw; })
      cpusPerTask ntasksPerNode;

    nodes = c.nodes;
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
