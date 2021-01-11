{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools

# Options for the experiment
, enableJemalloc ? false
, enableCTF ? false
# Number of cases tested
, steps ? 7
# nbody iterations
, timesteps ? 10
# nbody total number of particles
, particles ? null
, gitBranch ? "garlic/tampi+send+oss+task"
, loops ? 10
, nblocks0 ? null
}:

with stdenv.lib;
with garlicTools;

let

  defaultOpt = var: def: if (var != null) then var else def;

  machineConfig = targetMachine.config;
  inherit (machineConfig) hw;

  # Initial variable configuration
  varConf = with bsc; {
    # Create a list with values 2^n with n from 0 to (steps - 1) inclusive
    i = expRange 2 0 (steps - 1);
  };

  # Generate the complete configuration for each unit
  genConf = var: fix (self: var // targetMachine.config // {
    expName = "nbody-nblocks";
    unitName = "${self.expName}${toString self.nblocks}";

    inherit (machineConfig) hw;

    # nbody options
    particles = defaultOpt particles (4096 * self.hw.cpusPerSocket);
    nblocks0 = defaultOpt nblocks0 (self.hw.cpusPerSocket / 2);
    # The number of blocks is then computed from the multiplier "i" and
    # the initial number of blocks "nblocks0"
    nblocks = self.i * self.nblocks0;

    totalTasks = self.ntasksPerNode * self.nodes;
    particlesPerTask = self.particles / self.totalTasks;
    blocksize = self.particlesPerTask / self.nblocks;
    cc = bsc.icc;
    mpi = bsc.impi;
    cflags = "-g";
    inherit timesteps gitBranch enableJemalloc enableCTF loops;

    # Resources
    qos = "debug";
    cpusPerTask = self.hw.cpusPerSocket;
    ntasksPerNode = self.hw.socketsPerNode;
    nodes = 1;
    jobName = self.unitName;
  });

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  perf = {nextStage, conf, ...}: with conf; stages.perf {
    inherit nextStage;
    perfOptions = "record --call-graph dwarf -o \\$\\$.perf";
  };

  ctf = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    env = optionalString (conf.enableCTF) ''
      export NANOS6_CONFIG_OVERRIDE="version.instrument=ctf,\
        instrument.ctf.conversor.enabled=false"
    '';
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    argv = [ "-t" timesteps "-p" particles ];
  };

  program = {nextStage, conf, ...}: with conf;
    let
      /* These changes are propagated to all dependencies. For example,
      when changing nanos6+jemalloc, we will get tampi built with
      nanos6+jemalloc as well. */
      customPkgs = bsc.extend (self: super: {
        mpi = conf.mpi;
        nanos6 = super.nanos6.override { inherit enableJemalloc; };
      });
    in
      customPkgs.apps.nbody.override ({
        inherit cc blocksize mpi gitBranch cflags;
      });

  pipeline = stdexp.stdPipeline ++ [ ctf exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
