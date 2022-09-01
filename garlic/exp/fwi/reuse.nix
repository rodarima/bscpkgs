# This test compares a FWI version using poor data locality (+NOREUSE) versus
# the optimized version (used for all other experiments). Follows a pseudocode
# snippet illustrating the fundamental difference between version.
#
# NOREUSE
# ----------------------
# for (y) for (x) for (z)
#   computA(v[y][x][z]);
# for (y) for (x) for (z)
#   computB(v[y][x][z]);
# for (y) for (x) for (z)
#   computC(v[y][x][z]);
#
# Optimized version
# ----------------------
# for (y) for (x) for (z)
#   computA(v[y][x][z]);
#   computB(v[y][x][z]);
#   computC(v[y][x][z]);

{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
, callPackage
}:

with lib;

let

  inherit (targetMachine) fs;

  # Initial variable configuration
  varConf = {
    gitBranch = [
       "garlic/mpi+send+oss+task"
       "garlic/mpi+send+oss+task+NOREUSE"
    ];

    blocksize = [ 1 2 4 8 ];

    n = [ {nx=300; ny=2000; nz=300;} ]; # / half node
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    expName = "fwi-reuse";
    unitName = "${expName}"
      + "-bs${toString blocksize}"
      + "-${toString gitBranch}";

    inherit (machineConfig) hw;
    inherit (c) gitBranch blocksize;
    inherit (c.n) nx ny nz;

    enableCTF = false;
    enableIO = true;

    # Repeat the execution of each unit several times
    loops = 10;

    # Resources
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = 1;
    nodes = 1;
    qos = "debug";
    time = "02:00:00";
    jobName = unitName;

    # Enable permissions to write in the local storage
    extraMounts = [ fs.local.temp ];
    tempDir = fs.local.temp;
  };

  common = callPackage ./common.nix {};

  inherit (common) getConfigs pipeline;

  configs = getConfigs {
    inherit varConf genConf;
  };

in
 
  stdexp.genExperiment { inherit configs pipeline; }
