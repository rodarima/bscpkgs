{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
}:

with lib;

let

  # Initial variable configuration
  varConf = with bsc; {
    gitBranch = [
      "garlic/mpi+isend+seq"
      "garlic/tampi+isend+oss+taskloop"
      "garlic/tampi+isend+oss+taskfor"
      "garlic/tampi+isend+oss+task"
      "garlic/mpi+isend+seq"
      "garlic/mpi+isend+oss+task"
      "garlic/mpi+isend+omp+fork"
      "garlic/tampi+isend+oss+taskloopfor"
    ];
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "lulesh";
    unitName = "${expName}-test";
    inherit (machineConfig) hw;

    # options
    iterations = 10;
    size = 30;
    gitBranch = c.gitBranch;
    
    # Repeat the execution of each unit several times
    loops = 10;

    # Resources
    qos = "debug";
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = 1;
    nodes = 1;
    time = "02:00:00";
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  /* Lulesh options:
     -q              : quiet mode - suppress all stdout
     -i <iterations> : number of cycles to run
     -s <size>       : length of cube mesh along side
     -r <numregions> : Number of distinct regions (def: 11)
     -b <balance>    : Load balance between regions of a domain (def: 1)
     -c <cost>       : Extra cost of more expensive regions (def: 1)
     -f <numfiles>   : Number of files to split viz dump into (def: (np+10)/9)
     -p              : Print out progress
     -v              : Output viz file (requires compiling with -DVIZ_MESH
     -h              : This message
  */
  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    argv = [ "-i" iterations "-s" size ];
  };

  apps = bsc.garlic.apps;

  program = {nextStage, conf, ...}: apps.lulesh.override {
    inherit (conf) gitBranch;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
