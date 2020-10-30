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
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    # Options for creams
    cc = icc;
    gitBranch = "seq";

    # Repeat the execution of each unit 30 times
    loops = 1;

    # Resources
    qos = "debug";
    nodes = 1;
    time = "02:00:00";
    ntasksPerNode = 1;
    cpuBind = "rank,verbose";
    jobName = "fwi-${gitBranch}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  # Custom stage to copy the FWI input
  copyInput = {nextStage, conf, ...}:
    let
      input = bsc.garlic.apps.fwi;
    in
      stages.exec {
        inherit nextStage;
        env = ''
          cp -r ${input}/bin/InputModels .
          chmod +w -R .
        '';
        argv = [
          "${input}/etc/fwi/fwi_params.txt"
          "${input}/etc/fwi/fwi_frequencies.txt"
        ];
      };

  # FWI program
  program = {nextStage, conf, ...}: with conf;
    bsc.garlic.apps.fwi.override {
      inherit cc gitBranch;
    };

  pipeline = stdexp.stdPipeline ++ [ copyInput program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
