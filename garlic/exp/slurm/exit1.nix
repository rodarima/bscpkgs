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
  varConf = {
    script = [
      "exit 1"
      "exit 0"
      "kill -SEGV $$"
      "kill -TERM $$"
    ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "exit1";
    unitName = expName + "-" +
      builtins.replaceStrings [" " "$"] ["-" "-"] script;

    inherit (machineConfig) hw;
    
    # Repeat the execution of each unit 30 times
    loops = 1;
    inherit (c) script;

    # Resources
    qos = "debug";
    cpusPerTask = 1;
    ntasksPerNode = 2;
    nodes = 1;
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    pre = "sleep 5";
    post = "echo dummy";
  };

  prog = {conf,...}: stages.script {
    inherit (conf) script;
  };

  pipeline = stdexp.stdPipeline ++ [ exec prog ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
