{
  stdenv
, stdexp
, bsc
, targetMachine
, stages

# Should we test the network (true) or the shared memory (false)?
, interNode ? true
}:

with builtins;
with stdenv.lib;

let

  machineConfig = targetMachine.config;

  # Initial variable configuration
  varConf = with bsc; {
    mpi = [ impi bsc.openmpi mpich ]; #psmpi ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    inherit (machineConfig) hw;
    nodes = if interNode then 2 else 1;
    ntasksPerNode = if interNode then 1 else 2;
    cpusPerTask = 1;
    time = "00:10:00";
    qos = "debug";
    loops = 30;
    expName = "osu-bw-${mpi.name}";
    unitName = expName;
    jobName = expName;
    inherit (c) mpi;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;

    program = "${nextStage}/bin/osu_bw";
  };

  program = {nextStage, conf, ...}: bsc.osumb.override {
    # Use the specified MPI implementation
    inherit (conf) mpi;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
