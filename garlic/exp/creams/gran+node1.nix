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
      { nodes=1 ; nprocz=2 ; granul=256; time= "02:00:00"; }
      { nodes=1 ; nprocz=2 ; granul=128; time= "02:00:00"; }
      { nodes=1 ; nprocz=2 ; granul=64;  time= "02:00:00"; }
      { nodes=1 ; nprocz=2 ; granul=37;  time= "02:00:00"; }
      { nodes=1 ; nprocz=2 ; granul=32;  time= "02:00:00"; }
      { nodes=1 ; nprocz=2 ; granul=16;  time= "02:00:00"; }
      { nodes=1 ; nprocz=2 ; granul= 9;  time= "02:00:00"; }
      { nodes=1 ; nprocz=2 ; granul= 5;  time= "02:00:00"; }
      { nodes=1 ; nprocz=2 ; granul= 4;  time= "02:00:00"; }
      { nodes=1 ; nprocz=2 ; granul= 2;  time= "02:00:00"; }
      { nodes=1 ; nprocz=2 ; granul= 1;  time= "02:00:00"; }
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
    expName = "creams-gran-node1";
    unitName = "${expName}-${toString nodes}-${gitBranch}";
    inherit (targetMachine.config) hw;
    # Options for creams
    cc = icc;
    mpi = impi;
    inherit (c.input) granul;
    inherit (c) gitBranch;
    nprocz = ntasksPerNode * nodes;

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    qos = "debug";
    ntasksPerNode = hw.socketsPerNode;
    cpusPerTask = hw.cpusPerSocket;
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
          # Only the MPI rank 0 will copy the files
          if [ $SLURM_PROCID == 0 ]; then
            cp -fr ${input}/SodTubeBenchmark/* .
            chmod +w -R .
          fi
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
