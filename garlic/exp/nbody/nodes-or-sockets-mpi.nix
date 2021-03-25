{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, numactl
}:

with stdenv.lib;
with garlicTools;

let
  # Initial variable configuration
  varConf = with bsc; {
    blocksize = [ 256 512 1024 ];
    gitBranch = [ "garlic/tampi+send+oss+task" ];
    attachToSocket = [ true false ];
    numactl = [ true false ];
  };

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    hw = targetMachine.config.hw;
    particles = 4 * 4096 * hw.cpusPerSocket;
    timesteps = 10;
    blocksize = c.blocksize;
    gitBranch = c.gitBranch;
    socketAtt = c.attachToSocket;
    useNumact = c.numactl;

    expName = "nbody-granularity";
    attachName = if (socketAtt) then "PerSocket" else "PerNode";
    numaName = if (useNumact) then "True" else "False";
    unitName = expName +
      "-${toString gitBranch}" +
      "-bs${toString blocksize}" +
      "-ranks${toString attachName}" +
      "-useNuma${toString numaName}";

    loops = 30;

    qos = "debug";
    ntasksPerNode = if (socketAtt) then 2 else 1;
    nodes = 4;
    time = "02:00:00";
    cpusPerTask = if (socketAtt) then hw.cpusPerSocket else 2*hw.cpusPerSocket;
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: stages.exec ({
    inherit nextStage;
    argv = [ "-t" conf.timesteps "-p" conf.particles ];
  } // optionalAttrs (conf.useNumact) {
    program = "${numactl}/bin/numactl --interleave=all ${stageProgram nextStage}";
  });

  program = {nextStage, conf, ...}: with conf; bsc.garlic.apps.nbody.override {
    inherit (conf) blocksize gitBranch;
  };
  
  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
