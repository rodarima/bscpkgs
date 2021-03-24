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

  # Initial variable configuration
  varConf = {
    blocksize = [ 128 256 512 1024 2048 4096 ];
  };

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    hw = targetMachine.config.hw;
    particles = 4096 * hw.cpusPerSocket;
    timesteps = 10;
    blocksize = c.blocksize;
    
    gitBranch = "garlic/oss+task";
    expName = "nbody-granularity";
    unitName = expName + "-bs${toString blocksize}";

    loops = 30;

    qos = "debug";
    ntasksPerNode = 1;
    nodes = 1;
    time = "02:00:00";
    cpusPerTask = hw.cpusPerSocket;
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;
    argv = [ "-t" conf.timesteps "-p" conf.particles ];
  };

  program = {nextStage, conf, ...}: with conf; bsc.garlic.apps.nbody.override {
    inherit (conf) blocksize gitBranch;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
