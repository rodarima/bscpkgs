{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages

# Should we test the network (true) or the shared memory (false)?
, interNode ? true
}:

with builtins;
with lib;

let

  machineConfig = targetMachine.config;

  # Initial variable configuration
  varConf = with bsc; {
    threshold = [ 8000 16000 32000 64000 ];
    #threshold = [ 4096 8192 10240 ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    inherit (machineConfig) hw;
    nodes = if interNode then 2 else 1;
    ntasksPerNode = if interNode then 1 else 2;
    mpi = impi;
    cpusPerTask = 1;
    time = "00:10:00";
    qos = "debug";
    loops = 10;
    expName = "osu-impi-rndv";
    unitName = expName + "-${toString threshold}";
    jobName = expName;
    inherit (c) threshold;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;
    env = ''
      export PSM2_MQ_RNDV_SHM_THRESH=${toString conf.threshold}
      export PSM2_MQ_RNDV_HFI_THRESH=${toString conf.threshold}
      export PSM2_MQ_EAGER_SDMA_SZ=${toString conf.threshold}
      #export PSM2_MTU=${toString conf.threshold}
      export PSM2_TRACEMASK=0x101
    '';

    program = "${nextStage}/bin/osu_bw";
  };

  program = {nextStage, conf, ...}: bsc.osumb.override {
    # Use the specified MPI implementation
    inherit (conf) mpi;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
