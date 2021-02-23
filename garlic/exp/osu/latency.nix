{
  stdenv
, stdexp
, bsc
, targetMachine
, stages

# Should we test the network (true) or the shared memory (false)?
, interNode ? true
}:

let
  # Initial variable configuration
  varConf = with bsc; {
    mpi = [ impi bsc.openmpi mpich ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    nodes = if interNode then 2 else 1;
    ntasksPerNode = if interNode then 1 else 2;
    cpusPerTask = 1;
    time = "00:10:00";
    qos = "debug";
    loops = 30;
    expName = "osu-latency-${mpi.name}";
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
    # We simply run the osu_latency test
    program = "${nextStage}/bin/osu_latency";
  };

  program = {nextStage, conf, ...}: bsc.osumb.override {
    # Use the specified MPI implementation
    inherit (conf) mpi;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
