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
    gitBranch = [ "garlic/mpi" ];
    makefileName = [ "MPI" ];
    n = [ 104 64 ];
  };

  # Common configuration
  common = {
    # Resources
    ntasksPerNode = "48";
    nodes = "1";

    # Stage configuration
    enableSbatch = true;
    enableControl = true;
    enableExtrae = false;
    enablePerf = false;
    enableCtf = false;

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
      jobName = "hpcg";
      inherit nixPrefix nodes ntasksPerNode;
    }
  );

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
    nixsetup = "${nixPrefix}/bin/nix-setup";
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

  argv = {stage, conf, ...}: with conf; w.argv {
    program = stageProgram stage;
    argv = ''(
      --nx=${toString n}
      --ny=${toString n}
      --nz=${toString n}
    )'';
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

  hpcgFn = {stage, conf, ...}: with conf;
    let
      # We set the mpi implementation to the one specified in the conf, so all
      # packages in bsc will use that one.
      customPkgs = genPkgs (self: super: {
        bsc = super.bsc // { mpi = conf.mpi; };
      });
    in
    customPkgs.bsc.garlic.hpcg.override {
      inherit cc mpi gitBranch makefileName;
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

    # Optionally profile nanos6 with the new ctf
    ++ optional enableCtf ctf

    # Execute the hpcg app with the argv and env vars
    ++ [ argv hpcgFn ];

  # List of actual programs to be executed
  jobs = map (conf: w.stagen { inherit conf stages; }) configs;

in
  # We simply run each program one after another
  w.launch jobs
