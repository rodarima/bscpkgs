{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
}:

with lib;
with garlicTools;

let

  machineConfig = targetMachine.config;

  inherit (machineConfig) hw;

  # Initial variable configuration
  varConf = with bsc; {
    # Create a list of cpus per task by computing the divisors of the number of
    # cpus per socket, example: divisors 24 = [ 1 2 3 4 6 8 12 24 ]
    cpusPerTask = divisors hw.cpusPerSocket;
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
    # As cpusPerTask is a divisor of the cpusPerSocket and thus cpusPerNode, we
    # know the remainder is zero:
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
