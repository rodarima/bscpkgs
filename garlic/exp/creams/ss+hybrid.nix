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
      { nodes=1 ; nprocz=2 ; granul=37; time= "10:00:00"; }
      { nodes=2 ; nprocz=4 ; granul=19; time= "05:00:00"; }
      { nodes=4 ; nprocz=8 ; granul=10; time= "03:00:00"; }
      { nodes=8 ; nprocz=16; granul=9 ; time= "02:00:00"; }
      { nodes=16; nprocz=32; granul=9 ; time= "01:00:00"; }
    ];

    gitBranch = [
      "garlic/mpi+isend+oss+task"
      "garlic/mpi+send+omp+fork"
      "garlic/mpi+send+oss+task"
      "garlic/tampi+isend+oss+task"
    ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    # Options for creams
    cc = icc;
    mpi = impi;
    inherit (c.input) granul;
    inherit (c) gitBranch;
    nprocz = 2 * nodes;

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    qos = "debug";
    ntasksPerNode = 2;
    inherit (c.input) time nodes;
    cpuBind = "socket,verbose";
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
