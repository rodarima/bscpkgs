# Strong scaling test for FWI variants based on tasks. This
# experiment explores a range of block sizes deemed as efficient
# according to the granularity experiment.

{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, callPackage
, enableExtended ? false
}:

with stdenv.lib;
with garlicTools;

let
  common = callPackage ./common.nix {};
  inherit (common) getConfigs getResources pipeline;

  inherit (targetMachine) fs;

  # Initial variable configuration
  varConf = {
    gitBranch = [
      "garlic/tampi+isend+oss+task"
    ] ++ optionals (enableExtended) [
      "garlic/tampi+send+oss+task"
      "garlic/mpi+send+omp+task"
      "garlic/mpi+send+oss+task"
      "garlic/mpi+send+omp+fork"
      # FIXME: the mpi pure version has additional constraints with the
      # number of planes in Y. By now is disabled.
      #"garlic/mpi+send+seq"
    ];

    blocksize = if (enableExtended)
      then range2 1 16
      else [ 2 ];

    n = [ { nx=100; ny=8000; nz=100; } ];

    nodes = range2 1 16;
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = c: machineConfig // rec {
    expName = "fwi-ss";
    unitName = "${expName}"
    + "-nodes${toString nodes}"
    + "-bs${toString blocksize}"
    + "-${toString gitBranch}";

    inherit (machineConfig) hw;
    inherit (c) gitBranch blocksize;
    inherit (c.n) nx ny nz;

    # Other FWI parameters
    enableIO = true;
    enableCTF = false;

    # Repeat the execution of each unit several times
    loops = 10;

    # Resources
    inherit (getResources { inherit gitBranch hw; })
      cpusPerTask ntasksPerNode;

    nodes = c.nodes;
    qos = "debug";
    time = "02:00:00";
    jobName = unitName;

    # Enable permissions to write in the local storage
    extraMounts = [ fs.local.temp ];
    tempDir = fs.local.temp;
  };

  configs = getConfigs {
    inherit varConf genConf;
  };

in
 
  stdexp.genExperiment { inherit configs pipeline; }
