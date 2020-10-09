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
      { time="10:00:00"; nodes=1;  }
      { time="05:00:00"; nodes=2;  }
      { time="03:00:00"; nodes=4;  }
      { time="02:00:00"; nodes=8;  }
      { time="01:00:00"; nodes=16; }
    ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    # Options for creams
    cc = icc;
    mpi = impi;
    granul = 0;
    gitBranch = "garlic/mpi+send+seq";
    nprocz = 48 * nodes;

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    qos = "debug";
    ntasksPerNode = 48;
    inherit (c.input) time nodes;
    cpuBind = "rank,verbose";
    jobName = "creams-ss-${toString nodes}-${gitBranch}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
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

  pipeline = stdexp.stdPipeline ++ [ copyInput creams ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
