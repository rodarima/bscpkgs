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
    n = [ { x = 96; y = 96; z = 96; } ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    # hpcg options
    n = c.n;
    cc = bsc.icc;
    mpi = bsc.impi;
    gitBranch = "garlic/mpi";

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    qos = "debug";
    ntasksPerNode = 1;
    nodes = 24;
    time = "02:00:00";
    # Each task in different socket
    cpuBind = "verbose,mask_cpu:0x1";
    jobName = "hpcg-${toString n.x}-${toString n.y}-${toString n.z}-${gitBranch}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    argv = [
      "--nx=${toString n.x}"
      "--ny=${toString n.y}"
      "--nz=${toString n.z}"
    ];
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.hpcg.override {
      inherit cc mpi gitBranch;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }