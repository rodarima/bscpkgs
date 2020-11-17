{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, enableJemalloc ? false
, particles ? null
}:

with stdenv.lib;
with garlicTools;

let

  machineConfig = targetMachine.config;
  inherit (machineConfig) hw;

  # Number of cases tested
  steps = 7;

  # First value for nblocks: we want to begin by using 1/2 blocks/cpu so we set
  # the first number of blocks to cpusPerSocket / 2
  nblocks0 = hw.cpusPerSocket / 2;

  # Initial variable configuration
  varConf = with bsc; {
    # Create a list with values 2^n with n from 0 to (steps - 1) inclusive
    i = expRange 2 0 (steps - 1);
  };

  # Set here the particles, so we don't have an infinite recursion in the
  # genConf attrset.
  _particles = if (particles != null)
    then particles
    else 4096 * hw.cpusPerSocket;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "nbody-nblocks";
    unitName = "${expName}${toString nblocks}";

    inherit (machineConfig) hw;
    # nbody options
    particles = _particles;
    timesteps = 10;
    nblocks = c.i * nblocks0;
    totalTasks = ntasksPerNode * nodes;
    particlesPerTask = particles / totalTasks;
    blocksize = particlesPerTask / nblocks;
    cc = icc;
    mpi = impi;
    gitBranch = "garlic/tampi+send+oss+task";
    cflags = "-g";
    inherit enableJemalloc;
    
    # Repeat the execution of each unit 10 times
    loops = 10;

    # Resources
    qos = "debug";
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = hw.socketsPerNode;
    nodes = 1;

    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  perf = {nextStage, conf, ...}: with conf; stages.perf {
    inherit nextStage;
    perfOptions = "record --call-graph dwarf -o \\$\\$.perf";
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    argv = [ "-t" timesteps "-p" particles ];
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.nbody.override ({
      inherit cc blocksize mpi gitBranch cflags;
    } // optionalAttrs enableJemalloc {
      mcxx = bsc.mcxx.override {
        nanos6 = bsc.nanos6Jemalloc;
      };
    });

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
