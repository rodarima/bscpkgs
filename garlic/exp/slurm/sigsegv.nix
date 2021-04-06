{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
}:

with stdenv.lib;
with garlicTools;

let

  machineConfig = targetMachine.config;

  inherit (machineConfig) hw;

  # Initial variable configuration
  varConf = {
    when = [ "before" "after" "never" ];
  };

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    expName = "sigsegv";
    unitName = expName + "-" + when;

    inherit (machineConfig) hw;
    inherit (c) when;
    
    loops = 3;

    # Resources
    qos = "debug";
    cpusPerTask = 1;
    ntasksPerNode = hw.cpusPerNode;
    nodes = 1;
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    env = "date";
    argv = [ conf.when ];
  };

  program = {nextStage, conf, ...}: bsc.test.sigsegv;

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
