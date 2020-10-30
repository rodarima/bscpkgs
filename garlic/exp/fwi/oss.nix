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
    blocksize = [ 1 2 4 8 16 ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    # Options for creams
    cc = icc;
    gitBranch = "oss";
    inherit (c) blocksize;

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    qos = "debug";
    nodes = 1;
    time = "02:00:00";
    ntasksPerNode = 1;
    cpuBind = "sockets,verbose";
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
          "${toString conf.blocksize}"
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
