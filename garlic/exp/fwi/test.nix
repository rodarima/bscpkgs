{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
}:

with stdenv.lib;

let
  # Initial variable configuration
  varConf = {
    gitBranch = [
      "garlic/tampi+send+oss+task"
      "garlic/mpi+send+omp+task"
      "garlic/mpi+send+oss+task"
      "garlic/mpi+send+seq"
      "garlic/oss+task"
      "garlic/omp+task"
      "garlic/seq"
    ];
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "fwi";
    unitName = "${expName}-test";
    inherit (machineConfig) hw;

    cc = icc;
    gitBranch = c.gitBranch;

    # Repeat the execution of each unit several times
    loops = 10;

    # Resources
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = 1;
    nodes = 1;
    qos = "debug";
    time = "02:00:00";
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  # Custom stage to copy the FWI input
  #copyInput = {nextStage, conf, ...}:
  #  let
  #    input = bsc.garlic.apps.fwi;
  #  in
  #    stages.exec {
  #      inherit nextStage;
  #      env = ''
  #        cp -r ${input}/bin/InputModels .
  #        chmod +w -R .
  #      '';
  #      argv = [
  #        "${input}/etc/fwi/fwi_params.txt"
  #        "${input}/etc/fwi/fwi_frequencies.txt"
  #      ];
  #    };

  apps = bsc.garlic.apps;

  # FWI program
  program = {nextStage, conf, ...}: apps.fwi.solver.override {
    inherit (conf) cc gitBranch;
  };

  pipeline = stdexp.stdPipeline ++ [ program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
