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
    input = [
      { time="02:00:00"; nodes=1;  }
      { time="02:00:00"; nodes=2;  }
      { time="02:00:00"; nodes=4;  }
      { time="02:00:00"; nodes=8;  }
      { time="02:00:00"; nodes=16; }
    ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "creams-ss";
    unitName = "${expName}-${toString nodes}-${gitBranch}";
    inherit (targetMachine.config) hw;
    # Options for creams
    cc = icc;
    mpi = impi;
    granul = 0;
    gitBranch = "garlic/mpi+send+seq";
    nprocz = ntasksPerNode * nodes;

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    qos = "debug";
    ntasksPerNode = hw.cpusPerNode;
    cpusPerTask = 1;
    inherit (c.input) time nodes;
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  # Use nanos6 with regions
  nanos6Env = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    env = ''
      export NANOS6_CONFIG_OVERRIDE="version.dependencies=regions"
    '';
  };

  # Custom stage to copy the creams input dataset
  copyInput = {nextStage, conf, ...}:
    let
      input = bsc.garlic.apps.creamsInput.override {
        inherit (conf) gitBranch granul nprocz;
      };
    in
      stages.exec {
        inherit nextStage;
        env = ''
          cp -r ${input}/SodTubeBenchmark/* .
          chmod +w -R .
        '';
      };

  # Creams program
  creams = {nextStage, conf, ...}: with conf;
    let
      customPkgs = stdexp.replaceMpi conf.mpi;
    in
      customPkgs.apps.creams.override {
        inherit cc mpi gitBranch;
      };

  pipeline = stdexp.stdPipeline ++ [ nanos6Env copyInput creams ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
