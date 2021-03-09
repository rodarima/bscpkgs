{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, enablePerf ? false
}:

with stdenv.lib;
with garlicTools;

let
  # Initial variable configuration
  varConf = with bsc; {
    cbs = range2 8 4096;
    rbs = range2 32 4096;
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "heat";
    unitName = expName +
      ".cbs-${toString cbs}" +
      ".rbs-${toString rbs}";

    inherit (machineConfig) hw;

    # heat options
    timesteps = 10;
    cols = 1024 * 16; # Columns
    rows = 1024 * 16; # Rows
    cbs = c.cbs;
    rbs = c.rbs;
    gitBranch = "garlic/tampi+isend+oss+task";
    
    # Repeat the execution of each unit 30 times
    loops = 10;

    # Resources
    qos = "debug";
    ntasksPerNode = 1;
    nodes = 1;
    time = "02:00:00";
    # Assign one socket to each task (only one process)
    cpusPerTask = hw.cpusPerSocket;
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  perf = {nextStage, conf, ...}: stages.perf {
    inherit nextStage;
    perfOptions = "stat -o .garlic/perf.csv -x , " +
      "-e cycles,instructions,cache-references,cache-misses";
  };

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;
    argv = [
      "--rows" conf.rows
      "--cols" conf.cols
      "--rbs" conf.rbs
      "--cbs" conf.cbs
      "--timesteps" conf.timesteps
    ];

    # The next stage is the program
    env = ''
      ln -sf ${nextStage}/etc/heat.conf heat.conf || true
    '';
  };

  program = {nextStage, conf, ...}: bsc.garlic.apps.heat.override {
    inherit (conf) gitBranch;
  };

  pipeline = stdexp.stdPipeline ++
    (optional enablePerf perf) ++
    [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
