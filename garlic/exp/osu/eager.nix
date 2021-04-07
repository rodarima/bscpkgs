{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
}:

with builtins;
with stdenv.lib;

let

  machineConfig = targetMachine.config;

  # Initial variable configuration
  varConf = with bsc; {
    sizeKB = range 5 25;
    mpi = [ impi ];
    #mpi = [ impi bsc.openmpi mpich ]; #psmpi ];
    PSM2_MQ_EAGER_SDMA_SZ_KB = [ 16 20 24 ];
    PSM2_MTU_KB = [ 10 ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    inherit (machineConfig) hw;
    nodes = 2;
    ntasksPerNode = 1;
    cpusPerTask = 1;
    time = "00:30:00";
    qos = "debug";
    loops = 10;
    iterations = 50000;
    #FIXME: Notice the switchover is 16000 and MTU is 10240
    PSM2_MQ_EAGER_SDMA_SZ = PSM2_MQ_EAGER_SDMA_SZ_KB * 1000;
    PSM2_MTU = PSM2_MTU_KB * 1024;
    expName = "osu-bw";
    unitName = expName +
      "-size.${toString sizeKB}K" +
      "-mtu.${toString PSM2_MTU_KB}K" +
      "-sdma.${toString PSM2_MQ_EAGER_SDMA_SZ_KB}K";
    jobName = expName;
    inherit (c) mpi sizeKB
      PSM2_MQ_EAGER_SDMA_SZ_KB
      PSM2_MTU_KB;

    size = sizeKB * 1024;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;

    program = "${nextStage}/bin/osu_bw";

    env = ''
      export PSM2_MQ_EAGER_SDMA_SZ=${toString PSM2_MQ_EAGER_SDMA_SZ}
      export PSM2_MTU=${toString PSM2_MTU}
      export PSM2_TRACEMASK=0x101
      export PSM2_MQ_PRINT_STATS=-1
    '';

    argv = [
      "-m" "${toString size}:${toString size}"
      "-i" iterations
    ];
  };

  program = {nextStage, conf, ...}: bsc.osumb.override {
    # Use the specified MPI implementation
    inherit (conf) mpi;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
