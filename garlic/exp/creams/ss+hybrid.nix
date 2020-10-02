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
    cc  = [ bsc.icc  ]; # [ bsc.icc  pkgs.gfortran10 ];

    mpi = [ bsc.impi ]; # [ bsc.impi bsc.openmpi-mn4 ];

    input = [
      { nodes=1 ; nprocz=2 ; granul=37; time= "10:00:00"; }
      { nodes=2 ; nprocz=4 ; granul=19; time= "05:00:00"; }
      { nodes=4 ; nprocz=8 ; granul=10; time= "03:00:00"; }
      { nodes=8 ; nprocz=16; granul=9 ; time= "02:00:00"; }
      { nodes=16; nprocz=32; granul=9 ; time= "01:00:00"; }
    ];

    gitBranch = [ "garlic/mpi+isend+oss+task"
                  "garlic/mpi+send+omp+fork"
                  "garlic/mpi+send+oss+task"
                  "garlic/tampi+isend+oss+task"
    ];
  };

  # Common configuration
  common = {
    # Resources
    ntasksPerNode   = 2;
    #ntasksPerSocket = 1; // Add this variable to nix

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

  sbatch = {stage, conf, ...}: with conf; w.sbatch {
    nodes = input.nodes;
    program = stageProgram stage;
    exclusive = true;
    time = input.time;
    #qos = "debug";
    jobName = "creams-ss-${toString input.nodes}-${toString gitBranch}";
    inherit nixPrefix ntasksPerNode;
  };

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

  bscOverlay = import ../../../overlay.nix;

  genPkgs = newOverlay: nixpkgs {
    overlays = [
      bscOverlay
      newOverlay
    ];
  };

  inputDataset = {stage, conf, ...}:
  let
    input = bsc.garlic.creamsInput.override {
      gitBranch = conf.gitBranch;
      granul = conf.input.granul;
      nprocz = conf.input.nprocz;
    };
  in w.argv
  {
    program = stageProgram stage;
    env = ''
      cp -r ${input}/SodTubeBenchmark/* .
      chmod +w -R .
    '';
  };

  # We may be able to use overlays by invoking the fix function directly, but we
  # have to get the definition of the bsc packages and the garlic ones as
  # overlays.

  creamsFn = {stage, conf, ...}: with conf;
    let
      # We set the mpi implementation to the one specified in the conf, so all
      # packages in bsc will use that one.
      customPkgs = genPkgs (self: super: {
        bsc = super.bsc // { mpi = conf.mpi; };
      });
    in
    customPkgs.bsc.garlic.creams.override {
      inherit cc mpi gitBranch;
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

    # Execute the app with the argv and env vars
    ++ [ inputDataset creamsFn ];

  # List of actual programs to be executed
  jobs = map (conf: w.stagen { inherit conf stages; }) configs;

in
  # We simply run each program one after another
  w.launch jobs
