{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, enableJemalloc ? false
, enableFreeCpu ? false
}:

with stdenv.lib;

let
  # Initial variable configuration
  varConf = with bsc; {
    # We need at least cpusPerNode blocks
    nblocks = [ 4 8 16 32 64 128 256 512 ];
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    inherit (machineConfig) hw;
    # nbody options
    particles = 1024 * 32;
    timesteps = 10;
    inherit (c) nblocks;
    totalTasks = ntasksPerNode * nodes;
    particlesPerTask = particles / totalTasks;
    blocksize = particlesPerTask / nblocks;
    assert1 = assertMsg (nblocks >= hw.cpusPerSocket)
      "nblocks too low: ${toString nblocks} < ${toString hw.cpusPerSocket}";
    assert2 = assertMsg (particlesPerTask >= nblocks)
      "too few particles: ${toString particlesPerTask} < ${toString nblocks}";
    cc = icc;
    mpi = impi;
    gitBranch = "garlic/tampi+send+oss+task";
    cflags = "-g";
    
    # Repeat the execution of each unit 30 times
    loops = 10;

    # Resources
    qos = "debug";
    ntasksPerNode = hw.socketsPerNode;
    nodes = 1;
    time = "02:00:00";
    cpuBind = if (enableFreeCpu)
      then "verbose,mask_cpu:0x7fffff,0x7fffff000000"
      else "sockets,verbose";
    jobName = "bs-${toString blocksize}-${gitBranch}-nbody";
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
