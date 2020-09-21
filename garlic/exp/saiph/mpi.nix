{
  bsc
, nbody
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
    cc = [ bsc.icc ];
    blocksize = [ 2048 ];
    mpi = [ bsc.impi bsc.openmpi bsc.mpich ];
  };

  extraConfig = {
    particles = 32*1024;
    timesteps = 10;
    ntasksPerNode = 2;
    nodes = 1;
    time = "00:10:00";
    qos = "debug";
    #mpi = bsc.impi;
    #mpi = bsc.openmpi;
    gitBranch = "garlic/mpi+send";
    gitURL = "ssh://git@bscpm02.bsc.es/garlic/apps/nbody.git";
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

  argv = conf: app:
    with conf;
    argvWrapper {
      app = app;
      argv = ''(-t ${toString timesteps} -p ${toString particles})'';
      env = ''
        export I_MPI_THREAD_SPLIT=1
      '';
    };

  nbodyFn = conf:
    with conf;
    nbody.override { inherit cc mpi blocksize gitBranch gitURL; };

  pipeline = conf:
    sbatch conf (
      srun (
        nixsetupWrapper (
          argv conf (
            nbodyFn conf
          )
        )
      )
    )
    ;

  # Ideally it should look like this:
  #pipeline = sbatch nixsetup control argv nbodyFn;

  jobs = map pipeline configs;

in
  launchWrapper jobs
