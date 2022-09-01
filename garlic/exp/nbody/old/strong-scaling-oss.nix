{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
}:

with lib;

let
  # Initial variable configuration
  varConf = with bsc; {
    numProcsAndParticles = [ 1 2 4 8 16 32 48 ];
    input = [
      { numParticles=1 ; cpuMask="0x1"; }
      { numParticles=2 ; cpuMask="0x3"; }
      { numParticles=4 ; cpuMask="0xf"; }
      { numParticles=8 ; cpuMask="0xff"; }
      { numParticles=16; cpuMask="0xffff"; }
      { numParticles=32; cpuMask="0xffffffff"; }
      { numParticles=48; cpuMask="0xffffffffffff"; }
    ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    # nbody options
    inherit (c.input) numParticles cpuMask;
    particles = 1024 * numParticles * 2;
    timesteps = 10;
    blocksize = 1024;
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
    jobName = "nbody-bs-${toString numParticles}-${gitBranch}";
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
