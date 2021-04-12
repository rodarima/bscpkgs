# Regular granularity test for FWI

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

  inherit (targetMachine) fs;

  # Initial variable configuration
  varConf = {
    gitBranch = [ "garlic/tampi+isend+oss+task" ];
    blocksize = range2 1 256;
    n = [ {nx=100; nz=100; ny=8000; ntpn=2; nodes=1;} ];
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    expName = "fwi-granularity";
    unitName = "${expName}"
      + "-bs${toString blocksize}"
      + "-${toString gitBranch}";

    inherit (machineConfig) hw;
    inherit (c) gitBranch blocksize;
    inherit (c.n) nx ny nz ntpn nodes;

    # Other FWI parameters
    enableIO = true;
    enableCTF = false;

    # Repeat the execution of each unit several times
    loops = 10;

    # Resources
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = ntpn;
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
