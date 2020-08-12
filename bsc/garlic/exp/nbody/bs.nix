{
  bsc
, nbody
, genApp
, genConfigs

# Wrappers
, launcherWrapper
, sbatchWrapper
, argvWrapper
, controlWrapper
, nixsetupWrapper
}:

let
  # Set the configuration for the experiment
  config = {
    cc = [ bsc.icc ];
    blocksize = [ 1024 2048 4096 8192 ];
  };

  extraConfig = {
    particles = 16384;
    timesteps = 10;
    ntasks = 1;
    nnodes = 1;
  };

  # Compute the cartesian product of all configurations
  allConfigs = genConfigs config;

  configs = with builtins; filter (c: c.blocksize <= 4096) allConfigs;

  sbatch = conf: app: sbatchWrapper {
    app = app;
    nixPrefix = "/gpfs/projects/bsc15/nix";
    exclusive = false;
    ntasks = "${toString conf.ntasks}";
    chdirPrefix = "/home/bsc15/bsc15557/bsc-nixpkgs/out";
  };

  argv = conf: app:
    with conf;
    argvWrapper {
      app = app;
      argv = ''(-t ${toString timesteps} -p ${toString particles})'';
    };

  nbodyFn = conf:
    with conf;
    nbody.override { inherit cc blocksize; };

  pipeline = conf:
    sbatch conf (
      nixsetupWrapper (
        controlWrapper (
          argv conf (
            nbodyFn conf))));

  # Ideally it should look like this:
  #pipeline = sbatch nixsetup control argv nbodyFn;

  jobs = map (conf: pipeline (conf // extraConfig)) configs;

in
  launcherWrapper jobs
