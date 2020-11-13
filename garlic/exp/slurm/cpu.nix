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
  varConf = with bsc; {
    # Create a list of cpus per task by dividing cpusPerSocket by 2
    # successively. Example: divList 24 = [ 1 3 6 12 24 ]
    cpusPerTask = divList hw.cpusPerSocket;
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "cpu";
    unitName = "${expName}.${toString cpusPerTask}";

    inherit (machineConfig) hw;
    
    # Repeat the execution of each unit 30 times
    loops = 1;

    # Resources
    qos = "debug";
    inherit (c) cpusPerTask;
    ntasksPerNode = hw.cpusPerNode / cpusPerTask;
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
  };

  program = {nextStage, conf, ...}: bsc.dummy;

  pipeline = stdexp.stdPipeline ++ [ program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
