{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, enableExtended ? false
}:

with lib;
with garlicTools;

let
  # Initial variable configuration
  varConf = {

    #nodes = range2 1 16;
    nodes = [ 16 ];
    sizeFactor = range2 1 32;
    baseGranul = [ 1 ] ++ optionals (enableExtended) [ 2 4 8 ];

    # Max. number of iterations
    iterations = [ 20 ] ++ optionals (enableExtended) [ 10 ];

    gitBranch = [
      "garlic/tampi+isend+oss+task"
      "garlic/mpi+send+omp+fork"
      #"garlic/mpi+send+omp+task"
      #"garlic/mpi+send+seq"
    ] ++ (optionals (enableExtended) [
      "garlic/mpi+send+oss+task"
      "garlic/mpi+isend+omp+task"
      "garlic/mpi+isend+oss+task"
    ]);
  };

  # We use these auxiliary functions to assign different configurations
  # depending on the git branch.
  getGranul = branch: oldGranul:
    if (branch == "garlic/mpi+send+seq")
    then 999999 else oldGranul;

  getCpusPerTask = branch: hw:
    if (branch == "garlic/mpi+send+seq")
    then 1 else hw.cpusPerSocket;

  getNtasksPerNode = branch: hw:
    if (branch == "garlic/mpi+send+seq")
    then hw.cpusPerNode else hw.socketsPerNode;

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {

    expName = "creams-size";
    unitName = "${expName}"
    + "-granul.${toString granul}"
    + "-sf.${toString sizeFactor}";

    inherit (targetMachine.config) hw;

    # Options for creams
    inherit (c) iterations gitBranch nodes sizeFactor baseGranul;
    granul = getGranul gitBranch (max 2 (baseGranul * sizeFactor));
    nprocz = ntasksPerNode * nodes;
    baseSizePerCpu = 2;
    baseSize = baseSizePerCpu * cpusPerTask * ntasksPerNode * nodes;

    nz = baseSize * sizeFactor;

    # Repeat the execution of each unit 10 times
    loops = 10;

    # Resources
    qos = "debug";
    time = "02:00:00";
    ntasksPerNode = getNtasksPerNode gitBranch hw;
    cpusPerTask = getCpusPerTask gitBranch hw;
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = unique (stdexp.buildConfigs {
    inherit varConf genConf;
  });

  # Custom srun stage to copy the creams input dataset
  customSrun = {nextStage, conf, ...}:
  let
    input = bsc.garlic.apps.creamsInput.override {
      inherit (conf) gitBranch granul nprocz nz;
    };
  in
    stdexp.stdStages.srun {
      inherit nextStage conf;
      # Now we add some commands to execute before calling srun. These will
      # only run in one rank (the first in the list of allocated nodes)
      preSrun = ''
        cp -r ${input}/SodTubeBenchmark/* .
        chmod +w -R .
        sed -i '/maximum number of iterations/s/50/${toString conf.iterations}/' input.dat
        rm -f nanos6.toml
      '';
    };

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;
    env = ''
      export NANOS6_CONFIG_OVERRIDE="version.dependencies=regions"
    '';

    # Remove restarts as is not needed and is huge
    post = ''
      rm -rf restarts || true
    '';
  };

  # Creams program
  creams = {nextStage, conf, ...}: bsc.apps.creams.override {
    inherit (conf) gitBranch;
  };

  pipeline = stdexp.stdPipelineOverride {
    # Replace the stdandard srun stage with our own
    overrides = { srun = customSrun; };
  } ++ [ exec creams ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
