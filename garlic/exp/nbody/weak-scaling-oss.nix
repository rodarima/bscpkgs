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
    cpuMask = [ "0x1" "0x3" "0xf" "0xff" "0xffff" "0xffffffff" "0xffffffffffff" ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    # nbody options
    particles = 1024 * 64;
    timesteps = 10;
    blocksize = 1024;
    inherit (c) cpuMask;
    cc = icc;
    mpi = impi;
    gitBranch = "garlic/oss+task";

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    qos = "debug";
    ntasksPerNode = 1;
    nodes = 1;
    time = "02:00:00";
    cpuBind = "verbose,mask_cpu:${cpuMask}";
    jobName = "nbody-bs-${cpuMask}-${gitBranch}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    argv = [ "-t" timesteps "-p" particles ];
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.nbody.override {
      inherit cc blocksize mpi gitBranch;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
