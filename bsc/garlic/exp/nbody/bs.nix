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
  # Set variable configuration for the experiment
  varConfig = {
    cc = [ pkgs.bsc.icc ];
    blocksize = [ 1024 ];
  };

  # Common configuration
  common = {
    # Compile time nbody config
    gitBranch = "garlic/mpi+send";
    mpi = pkgs.bsc.impi;

    # nbody runtime options
    particles = 1024*128;
    timesteps = 20;

    # Resources
    ntasksPerNode = "48";
    nodes = "1";

    # Stage configuration
    enableSbatch = true;
    enableControl = true;
    enableExtrae = false;
    enablePerf = false;

    # MN4 path
    nixPrefix = "/gpfs/projects/bsc15/nix";
  };

  # Compute the cartesian product of all configurations
  configs = map (conf: conf // common) (genConfigs varConfig);

  stageProgram = stage:
    if stage ? programPath
    then "${stage}${stage.programPath}" else "${stage}";

  w = runWrappers;

  sbatch = {stage, conf, ...}: with conf; w.sbatch {
    program = stageProgram stage;
    exclusive = true;
    time = "02:00:00";
    qos = "debug";
    jobName = "nbody-bs";
    inherit nixPrefix nodes ntasksPerNode;
  };

  control = {stage, conf, ...}: with conf; w.control {
    program = stageProgram stage;
  };

  srun = {stage, conf, ...}: with conf; w.srun {
    program = stageProgram stage;
    srunOptions = "--cpu-bind=verbose,rank";
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
  };

  extrae = {stage, conf, ...}: w.extrae {
    program = stageProgram stage;
    traceLib = "mpi"; # mpi -> libtracempi.so
    configFile = ./extrae.xml;
  };

  argv = {stage, conf, ...}: w.argv {
    program = stageProgram stage;
    env = ''
      set -e
      export I_MPI_THREAD_SPLIT=1
    '';
    argv = ''( -t ${toString conf.timesteps}
      -p ${toString conf.particles} )'';
  };

  bscOverlay = import ../../../../overlay.nix;

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

  stages = with common; []
    # Use sbatch to request resources first
    ++ optional enableSbatch sbatch

    # Repeats the next stages N times
    ++ optionals enableControl [ nixsetup control ]

    # Executes srun to launch the program in the requested nodes, and
    # immediately after enters the nix environment again, as slurmstepd launches
    # the next stages from outside the namespace.
    ++ [ srun nixsetup ]

    # Intrumentation with extrae
    ++ optional enableExtrae extrae

    # Optionally profile the next stages with perf
    ++ optional enablePerf perf

    # Execute the nbody app with the argv and env vars
    ++ [ argv nbodyFn ];

  # List of actual programs to be executed
  jobs = map (conf: w.stagen { inherit conf stages; }) configs;

in
  # We simply run each program one after another
  w.launch jobs
