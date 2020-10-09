{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
}:

with stdenv.lib;

let
  # Configurations for each unit (using the cartesian product)
  confUnit = with bsc; {
    blocksize = [ 1024 2048 ];
  };

  # Configuration for the complete experiment
  confExperiment = with bsc; {
    # nbody options
    particles = 1024 * 4;
    timesteps = 10;
    cc = icc;
    mpi = impi;
    gitBranch = "garlic/mpi+send";

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    ntasksPerNode = 2;
    nodes = 1;
    cpuBind = "sockets,verbose";
  };

  confMachine = targetMachine.config;

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    var = confUnit;
    fixed = confMachine // confExperiment;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    argv = [ "-t" timesteps "-p" particles ];
    env = "";
  };

  # We may be able to use overlays by invoking the fix function directly, but we
  # have to get the definition of the bsc packages and the garlic ones as
  # overlays.
  program = {nextStage, conf, ...}: with conf;
  let
    # We set the mpi implementation to the one specified in the conf, so all
    # packages in bsc will use that one.
    customPkgs = stdexp.genPkgs (self: super: {
      bsc = super.bsc // { mpi = conf.mpi; };
    });
  in
  customPkgs.apps.nbody.override {
    inherit cc blocksize mpi gitBranch;
  };

  # Generate the experimental units
  units = map (c: stages.unit {
    conf = c;
    stages = stdexp.stdStages ++ [ exec program ];
  }) configs;

in
 
  stdexp.buildExperiment units
