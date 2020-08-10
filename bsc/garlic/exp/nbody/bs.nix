{
  bsc
, nbody
, genApp
, genConfigs
, sbatch
, launcher
}:

let
  # Set the configuration for the experiment
  config = {
    cc = [ bsc.icc ];
    blocksize = [ 1024 2048 4096 ];
  };

  # Compute the cartesian product of all configurations
  configList = genConfigs config;
  # Generate each app variant via override
  appList = genApp nbody configList;

  # Job generator helper function
  genJobs = map (app:
    sbatch {
      app = app;
      nixPrefix = "/gpfs/projects/bsc15/nix";
      exclusive = false;
      ntasks = "1";
      chdirPrefix = "/home/bsc15/bsc15557/bsc-nixpkgs/out";
    }
  );

  # Generate one job for each app variant
  jobList = genJobs appList;

  # And execute them all
  main = launcher jobList;
in
  main
