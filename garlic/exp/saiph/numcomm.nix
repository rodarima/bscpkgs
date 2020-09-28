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
    numComm = [ 1 ];
  };

  # Common configuration
  common = {
    # Compile time nbody config
    gitBranch = "Saiph_TAMPI_OMPSS";
    mpi = pkgs.bsc.impi;

    # Resources
    ntasksPerNode = "2";
    nodes = "2";

    # Stage configuration
    enableSbatch = true;
    enableControl = false;
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
    jobName = "saiph";
    inherit nixPrefix nodes ntasksPerNode;
  };

  control = {stage, conf, ...}: with conf; w.control {
    program = stageProgram stage;
  };

  srun = {stage, conf, ...}: with conf; w.srun {
    program = stageProgram stage;
    srunOptions = "--cpu-bind=verbose,sockets";
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

  extrae = {stage, conf, ...}:
    let
      # We set the mpi implementation to the one specified in the conf, so all
      # packages in bsc will use that one.
      customPkgs = genPkgs (self: super: {
        bsc = super.bsc // { mpi = conf.mpi; };
      });

      extrae = customPkgs.bsc.extrae;
    in
      w.extrae {
        program = stageProgram stage;
        extrae = extrae;
        traceLib = "nanosmpi"; # mpi -> libtracempi.so
        configFile = ./extrae.xml;
      };

  bscOverlay = import ../../../overlay.nix;

  genPkgs = newOverlay: nixpkgs {
    overlays = [
      bscOverlay
      newOverlay
    ];
  };

  # Print the environment to ensure we don't get anything nasty
  envRecord = {stage, conf, ...}: w.envRecord {
    program = stageProgram stage;
  };

  broom = {stage, conf, ...}: w.broom {
    program = stageProgram stage;
  };
  # We may be able to use overlays by invoking the fix function directly, but we
  # have to get the definition of the bsc packages and the garlic ones as
  # overlays.

  argv = {stage, conf, ...}: with conf; w.argv {
    program = stageProgram stage;
    env = ''
      export NANOS6_REPORT_PREFIX="#"
      export I_MPI_THREAD_SPLIT=1
    ''
    + optionalString enableExtrae
    ''export NANOS6=extrae
      export NANOS6_EXTRAE_AS_THREADS=0
    '';
  };

  saiphFn = {stage, conf, ...}: with conf;
    let
      # We set the mpi implementation to the one specified in the conf, so all
      # packages in bsc will use that one.
      customPkgs = genPkgs (self: super: {
        bsc = super.bsc // { mpi = conf.mpi; };
      });
    in
    customPkgs.bsc.garlic.saiph.override {
      inherit numComm mpi gitBranch;
    };

  stages = with common; []
    # Cleans ALL environment variables
    ++ [ broom ]

    # Use sbatch to request resources first
    ++ optionals enableSbatch [ sbatch nixsetup ]

    # Record the current env vars set by SLURM to verify we don't have something
    # nasty (like sourcing .bashrc). Take a look at #26
    ++ [ envRecord ]

    # Repeats the next stages N=30 times
    ++ optional enableControl control

    # Executes srun to launch the program in the requested nodes, and
    # immediately after enters the nix environment again, as slurmstepd launches
    # the next stages from outside the namespace.
    ++ [ srun nixsetup ]

    # Intrumentation with extrae
    ++ optional enableExtrae extrae

    # Optionally profile the next stages with perf
    ++ optional enablePerf perf

    # Execute the saiph example app
    ++ [ argv saiphFn ];

  # List of actual programs to be executed
  jobs = map (conf: w.stagen { inherit conf stages; }) configs;

in
  # We simply run each program one after another
  w.launch jobs
