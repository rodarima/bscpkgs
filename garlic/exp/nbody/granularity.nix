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
  varConf = with bsc; {
    blocksize = [ 128 256 512 1024 2048 4096 ];
    gitBranch = [
      "garlic/mpi+send+oss+task" 
      "garlic/tampi+send+oss+task" 
      "garlic/tampi+isend+oss+task"
    ];
  };

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    hw = targetMachine.config.hw;
    particles = 4096 * hw.cpusPerSocket;
    timesteps = 10;
    blocksize = c.blocksize;
    gitBranch = c.gitBranch;

    expName = "nbody-granularity";
    unitName = expName + "-${toString gitBranch}" + "-bs${toString blocksize}";

    loops = 30;

    qos = "bsc_cs";
    ntasksPerNode = 1;
    nodes = 1;
    time = "04:00:00";
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
