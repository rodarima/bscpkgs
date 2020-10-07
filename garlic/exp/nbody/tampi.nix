{
  stdenv
, nixpkgs
, pkgs
, genApp
, genConfigs
, runWrappers
}:

with stdenv.lib;

let
  bsc = pkgs.bsc;

  # Set variable configuration for the experiment
  varConfig = {
    cc = [ bsc.icc ];
    mpi = [ bsc.impi ];
    #mpi = [ bsc.mpichDebug ];
    blocksize = [ 1024 ];
  };

  # Common configuration
  common = {
    # Compile time nbody config
    gitBranch = "garlic/mpi+send";
    #gitBranch = "garlic/tampi+send+oss+task";

    # nbody runtime options
    particles = 1024*4;
    timesteps = 10;

    # Resources
    ntasksPerNode = "2";
    nodes = "1";

    # Stage configuration
    enableTrebuchet = true;
    enableSbatch    = true;
    enableControl   = true;
    enableExtrae    = false;
    enablePerf      = false;
    enableCtf       = false;
    enableStrace    = true;

    # MN4 path
    nixPrefix = "/gpfs/projects/bsc15/nix";
  };

  # Compute the cartesian product of all configurations
  configs = map (conf: conf // common) (genConfigs varConfig);

  stageProgram = stage:
    if stage ? programPath
    then "${stage}${stage.programPath}" else "${stage}";

  w = runWrappers;

  sbatch = {stage, conf, ...}: with conf; w.sbatch (
    # Allow a user to define a custom reservation for the job in MareNostrum4,
    # by setting the garlic.sbatch.reservation attribute in the 
    # ~/.config/nixpkgs/config.nix file. If the attribute is not set, no
    # reservation is used. The user reservation may be overwritten by the
    # experiment, if the reservation is set like with nodes or ntasksPerNode.
    optionalAttrs (pkgs.config ? garlic.sbatch.reservation) {
      inherit (pkgs.config.garlic.sbatch) reservation;
    } // {
      program = stageProgram stage;
      exclusive = true;
      time = "02:00:00";
      qos = "debug";
      jobName = "nbody-tampi";
      inherit nixPrefix nodes ntasksPerNode;
    }
  );

  control = {stage, conf, ...}: with conf; w.control {
    program = stageProgram stage;
  };

  srun = {stage, conf, ...}: with conf; w.srun {
    program = stageProgram stage;
    srunOptions = "--cpu-bind=verbose,socket";
    inherit nixPrefix;
  };

  statspy = {stage, conf, ...}: with conf; w.statspy {
    program = stageProgram stage;
  };

  perf = {stage, conf, ...}: with conf; w.perf {
    program = stageProgram stage;
    perfArgs = "sched record -a";
  };

  nixsetup = {stage, conf, ...}: with conf; w.nixsetup {
    program = stageProgram stage;
    nixsetup = "${nixPrefix}/bin/nix-setup";
  };

  isolate = {stage, conf, ...}: with conf; w.isolate {
    program = stageProgram stage;
    clusterName = "mn4";
    inherit nixPrefix;
  };

  extrae = {stage, conf, ...}: w.extrae {
    program = stageProgram stage;
    traceLib = "mpi"; # mpi -> libtracempi.so
    configFile = ./extrae.xml;
  };

  ctf = {stage, conf, ...}: w.argv {
    program = stageProgram stage;
    env = ''
      export NANOS6=ctf
      export NANOS6_CTF2PRV=0
    '';
  };

  strace = {stage, conf, ...}: w.strace {
    program = stageProgram stage;
  };

  argv = {stage, conf, ...}: w.argv {
    program = stageProgram stage;
    env = ''
      #export I_MPI_PMI_LIBRARY=${bsc.slurm17-libpmi2}/lib/libpmi2.so
      export I_MPI_DEBUG=+1000
      #export I_MPI_FABRICS=shm

      export MPICH_DBG_OUTPUT=VERBOSE
      export MPICH_DBG_CLASS=ALL
      export MPICH_DBG_OUTPUT=stdout

      export FI_LOG_LEVEL=Info
    '';
    argv = ''( -t ${toString conf.timesteps}
      -p ${toString conf.particles} )'';
  };

  bscOverlay = import ../../../overlay.nix;

  genPkgs = newOverlay: nixpkgs {
    overlays = [
      bscOverlay
      newOverlay
    ];
  };

  # We may be able to use overlays by invoking the fix function directly, but we
  # have to get the definition of the bsc packages and the garlic ones as
  # overlays.

  nbodyFn = {stage, conf, ...}: with conf;
    let
      # We set the mpi implementation to the one specified in the conf, so all
      # packages in bsc will use that one.
      customPkgs = genPkgs (self: super: {
        bsc = super.bsc // { mpi = conf.mpi; };
      });
    in
    customPkgs.bsc.garlic.nbody.override {
      inherit cc blocksize mpi gitBranch;
    };

  launch = w.launch.override {
    nixPrefix = common.nixPrefix;
  };

  stages = with common; []
    # Use sbatch to request resources first
    ++ optionals enableSbatch [
      sbatch
      nixsetup
      #isolate
    ]

    # Repeats the next stages N times
    ++ optional enableControl control

    # Executes srun to launch the program in the requested nodes, and
    # immediately after enters the nix environment again, as slurmstepd launches
    # the next stages from outside the namespace.
    ++ [
      #strace
      srun
      nixsetup
      #isolate
    ]

    # Intrumentation with extrae
    ++ optional enableExtrae extrae

    # Optionally profile the next stages with perf
    ++ optional enablePerf perf

    # Optionally profile nanos6 with the new ctf
    ++ optional enableCtf ctf

    # Optionally enable strace
    #++ optional enableStrace strace

    # Execute the nbody app with the argv and env vars
    ++ [ argv nbodyFn ];

  # List of actual programs to be executed
  jobs = map (conf: w.stagen { inherit conf stages; }) configs;

  launcher = launch jobs;

  trebuchet = stage: w.trebuchet {
    program = stageProgram stage;
    nixPrefix = common.nixPrefix;
  };

  isolatedRun = stage: isolate {
    inherit stage;
    conf = common;
  };

  final = trebuchet (isolatedRun launcher);

in
  # We simply run each program one after another
  #launch jobs
  final
