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
      { nodes=4 ; nprocz=8 ; granul=64;  time= "02:00:00"; }
      { nodes=4 ; nprocz=8 ; granul=37;  time= "02:00:00"; }
      { nodes=4 ; nprocz=8 ; granul=32;  time= "02:00:00"; }
      { nodes=4 ; nprocz=8 ; granul=16;  time= "02:00:00"; }
      { nodes=4 ; nprocz=8 ; granul= 9;  time= "02:00:00"; }
      { nodes=4 ; nprocz=8 ; granul= 5;  time= "02:00:00"; }
      { nodes=4 ; nprocz=4 ; granul= 4;  time= "02:00:00"; }
      { nodes=4 ; nprocz=8 ; granul= 2;  time= "02:00:00"; }
      { nodes=4 ; nprocz=8 ; granul= 1;  time= "02:00:00"; }
    ];

    gitBranch = [
      "garlic/mpi+send+omp+fork"
      "garlic/mpi+send+omp+task"
      "garlic/mpi+send+oss+task"
      "garlic/mpi+isend+omp+task"
      "garlic/mpi+isend+oss+task"
      "garlic/tampi+isend+oss+task"
    ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "creams-gran-node4";
    inherit (targetMachine.config) hw;
    # Options for creams
    cc = icc;
    mpi = impi;
    inherit (c.input) granul time nodes;
    inherit (c) gitBranch;
    unitName = "${expName}-${toString nodes}-${gitBranch}";

    # Repeat the execution of each unit 10 times
    loops = 10;

    # Resources
    qos = "debug";
    ntasksPerNode = hw.socketsPerNode;
    cpusPerTask = hw.cpusPerSocket;
    jobName = unitName;
    
    nprocz = ntasksPerNode * nodes;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  # Custom srun stage to copy the creams input dataset
  customSrun = {nextStage, conf, ...}:
    let
      input = bsc.garlic.apps.creamsInput.override {
        inherit (conf) gitBranch granul nprocz;
      };
    in
      stages.srun {
        # These are part of the stdndard srun stage:
        inherit (conf) nixPrefix;
        inherit nextStage;
        cpuBind = "cores,verbose";

        # Now we add some commands to execute before calling srun. These will
        # only run in one rank (the first in the list of allocated nodes)
        preSrun = ''
          cp -r ${input}/SodTubeBenchmark/* .
          chmod +w -R .
          rm -f nanos6.toml
        '';
      };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
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
  creams = {nextStage, conf, ...}: with conf;
    let
      customPkgs = stdexp.replaceMpi conf.mpi;
    in
      customPkgs.apps.creams.override {
        inherit cc mpi gitBranch;
      };

  pipeline = stdexp.stdPipelineOverride {
    overrides = {
      # Replace the stdandard srun stage with our own
      srun = customSrun;
    };
  } ++ [ exec creams ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
