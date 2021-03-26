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
    blocksize = [ 512 ];
    nodes = [ 1 2 4 8 16 ];
    gitBranch = [
      "garlic/mpi+send+oss+task" 
      "garlic/tampi+send+oss+task" 
      "garlic/tampi+isend+oss+task"
    ];
  };

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    hw = targetMachine.config.hw;
    particles = 16 * 4096 * hw.cpusPerSocket;
    timesteps = 10;
    blocksize = c.blocksize;
    numNodes  = c.nodes;
    gitBranch = c.gitBranch;

    expName = "nbody-scaling";
    unitName = expName + "-${toString gitBranch}" + "-nodes${toString numNodes}";

    loops = 30;

    nodes = numNodes;
    qos = "debug";
    ntasksPerNode = 2;
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
