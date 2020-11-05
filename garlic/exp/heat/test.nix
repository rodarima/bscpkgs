{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
}:

with stdenv.lib;

let
  # Initial variable configuration
  varConf = with bsc; {
    bsx = [ 1024 2048 4096 ];
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "heat";
    unitName = "${expName}.bsx-${toString bsx}";
    inherit (machineConfig) hw;

    # heat options
    inherit (c) bsx;
    timesteps = 10;
    
    # Repeat the execution of each unit 30 times
    loops = 10;

    # Resources
    qos = "debug";
    ntasksPerNode = 1;
    nodes = 1;
    time = "02:00:00";
    # Assign one socket to each task (only one process)
    cpuBind = "verbose,sockets";
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    argv = [ "-s" 1024 "-t" timesteps ];
    env = ''
      export LD_DEBUG=libs
      export NANOS6_LOADER_VERBOSE=1
      cp ${nextStage}/etc/heat.conf .
    '';
  };

  program = {nextStage, conf, ...}: with conf;
    bsc.garlic.apps.heat.override {
      inherit bsx;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
