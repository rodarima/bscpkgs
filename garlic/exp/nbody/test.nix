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

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    var = confUnit;
    fixed = targetMachine.config // confExperiment;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    argv = [ "-t" timesteps "-p" particles ];
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.nbody.override {
      inherit cc blocksize mpi gitBranch;
    };

  pipeline = stdexp.stdStages ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
