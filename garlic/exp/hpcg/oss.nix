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
    n = [ { x = 256; y = 288; z = 288; } ];
    nblocks = [ 12 24 48 96 192 384 ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    # hpcg options
    n = c.n;
    nblocks = c.nblocks;
    cc = bsc.icc;
    mcxx = bsc.mcxx;
    nanos6 = bsc.nanos6;
    mpi = null; # TODO: Remove this for oss
    gitBranch = "garlic/oss";

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    qos = "debug";
    ntasksPerNode = 1;
    nodes = 1;
    time = "02:00:00";
    # task in one socket
    cpuBind = "verbose,mask_cpu:0xffffff";
    jobName = "hpcg-${toString n.x}-${toString n.y}-${toString n.z}-${gitBranch}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    env = "NANOS6_DEPENDENCIES=discrete";
    argv = [
      "--nx=${toString n.x}"
      "--ny=${toString n.y}"
      "--nz=${toString n.z}"
      "--nblocks=${toString nblocks}"
    ];
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.hpcg.override {
      inherit cc nanos6 mcxx gitBranch;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }