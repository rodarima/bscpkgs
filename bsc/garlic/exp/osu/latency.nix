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

# Should we test the network (true) or the shared memory (false)?
, interNode ? true

# Enable multiple threads?
, multiThread ? false
}:

let
  # Set the configuration for the experiment
  config = {
    mpi = [ bsc.impi bsc.openmpi bsc.mpich ];
  };

  extraConfig = {
    nodes = if interNode then 2 else 1;
    ntasksPerNode = if interNode then 1 else 2;
    time = "00:10:00";
    qos = "debug";
  };

  # Compute the cartesian product of all configurations
  configs = map (conf: conf // extraConfig) (genConfigs config);

  sbatch = conf: app: sbatchWrapper {
    app = app;
    nixPrefix = "/gpfs/projects/bsc15/nix";
    exclusive = true;
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


  pipeline = conf:
    sbatch conf (
      nixsetupWrapper (
        controlWrapper (
          srun (
            nixsetupWrapper (
              argv (
                osumbFn conf))))));

  #pipeline = conf: sbatch conf (srun (nixsetupWrapper (argv (osumbFn conf))));
  #pipeline = conf: sbatch conf (srun (nixsetupWrapper (argv bsc.osumb)));

  # Ideally it should look like this:
  #pipeline = sbatch nixsetup control argv nbodyFn;

  jobs = map pipeline configs;

in
  launchWrapper jobs
