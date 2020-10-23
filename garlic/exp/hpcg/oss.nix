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
    n = [ 200 104 64 ];
    nblocks = [ 128 ];
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
    cpuBind = "sockets,verbose";
    jobName = "hpcg-${toString n}-${gitBranch}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    argv = [
      "--nx=${toString n}"
      "--ny=${toString n}"
      "--nz=${toString n}"
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
