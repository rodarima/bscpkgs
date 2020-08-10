{
  bsc
, nbody
, genApp
, genConfigs
, sbatch
, sbatchLauncher
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
      prefix = "/gpfs/projects/bsc15/nix";
      exclusive = false;
      ntasks = "1";
    }
  );

  # Generate one job for each app variant
  jobList = genJobs appList;

  # And merge all jobs in a script to lauch them all with sbatch
  launcher = sbatchLauncher jobList;
in
  launcher
