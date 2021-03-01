{
  stdenv
, stdexp
, bsc
, targetMachine
, stages

# Should we test the network (true) or the shared memory (false)?
, interNode ? true
, enableMultithread ? false
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
    cpusPerTask = if (enableMultithread) then hw.cpusPerSocket else 1;
    time = "00:10:00";
    qos = "debug";
    loops = 30;
    expName = "osu-latency-${mpi.name}";
    unitName = expName;
    jobName = expName;
    inherit (c) mpi;
    inherit enableMultithread;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;

    program = if (enableMultithread) then
      "${nextStage}/bin/osu_latency_mt"
    else
      "${nextStage}/bin/osu_latency";

    argv = optionals (enableMultithread) [
      "-t" "${toString conf.cpusPerTask}:${toString conf.cpusPerTask}"
    ];
  };

  program = {nextStage, conf, ...}: bsc.osumb.override {
    # Use the specified MPI implementation
    inherit (conf) mpi;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
