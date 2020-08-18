{
  bsc
, genApp
, genConfigs

# Wrappers
, launchWrapper
, sbatchWrapper
, srunWrapper
, argvWrapper
, controlWrapper
, nixsetupWrapper
}:

let
  # Set the configuration for the experiment
  config = {
    mpi = [ bsc.impi bsc.openmpi bsc.mpich ];
  };

  extraConfig = {
    ntasksPerNode = 1;
    nodes = 2;
    time = "00:10:00";
    qos = "debug";
  };

  # Compute the cartesian product of all configurations
  configs = map (conf: conf // extraConfig) (genConfigs config);

  sbatch = conf: app: sbatchWrapper {
    app = app;
    nixPrefix = "/gpfs/projects/bsc15/nix";
    exclusive = false;
    ntasksPerNode = "${toString conf.ntasksPerNode}";
    nodes = "${toString conf.nodes}";
    time = conf.time;
    qos = conf.qos;
    chdirPrefix = "/home/bsc15/bsc15557/bsc-nixpkgs/out";
  };

  srun = app: srunWrapper {
    app = app;
    nixPrefix = "/gpfs/projects/bsc15/nix";
  };

  argv = app:
    argvWrapper {
      app = app;
      program = "bin/osu_latency";
      argv = "()";
      env = ''
        export I_MPI_THREAD_SPLIT=1
      '';
    };

  osumbFn = conf:
    with conf;
    bsc.osumb.override { inherit mpi; };

  pipeline = conf: srun (nixsetupWrapper (argv (osumbFn conf)));
  #pipeline = conf: sbatch conf (srun (nixsetupWrapper (argv bsc.osumb)));

  # Ideally it should look like this:
  #pipeline = sbatch nixsetup control argv nbodyFn;

  jobs = map pipeline configs;

in
  launchWrapper jobs
