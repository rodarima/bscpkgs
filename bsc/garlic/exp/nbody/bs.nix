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
    blocksize = [ 1024 ];
  };

  extraConfig = {
    gitBranch = "garlic/mpi+send";
    mpi = bsc.impi;
    particles = 1024*128;
    timesteps = 10;
    ntasksPerNode = "48";
    nodes = "1";
    time = "02:00:00";
    qos = "debug";
  };

  # Compute the cartesian product of all configurations
  allConfigs = genConfigs config;
  filteredConfigs = with builtins; filter (c: c.blocksize <= 4096) allConfigs;
  configs = map (conf: conf // extraConfig) filteredConfigs;

  sbatch = conf: app: with conf; sbatchWrapper {
    app = app;
    nixPrefix = "/gpfs/projects/bsc15/nix";
    exclusive = true;
    inherit ntasksPerNode nodes time qos;
  };

  srun = app: srunWrapper {
    app = app;
    nixPrefix = "/gpfs/projects/bsc15/nix";
  };

  argv = conf: app:
    with conf;
    argvWrapper {
      app = app;
      env = ''
        set -e
        export I_MPI_THREAD_SPLIT=1
      '';
      argv = ''(-t ${toString timesteps} -p ${toString particles})'';
    };

  nbodyFn = conf:
    with conf;
    nbody.override { inherit cc mpi blocksize gitBranch; };

  pipeline = conf:
    sbatch conf (
      nixsetupWrapper (
        controlWrapper (
          srun (
            nixsetupWrapper (
              argv conf (
                nbodyFn conf))))));

  # Ideally it should look like this:
  #pipeline = sbatch nixsetup control argv nbodyFn;

  jobs = map pipeline configs;

in
  launchWrapper jobs
