# Strong scaling test for FWI variants based on tasks. This
# experiment explores a range of block sizes deemed as efficient
# according to the granularity experiment.

{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, enableExtended ? false
}:

with stdenv.lib;
with garlicTools;

let

  inherit (targetMachine) fs;

  # We split these into a separate group so we can remove the blocksize
  # later.
  forkJoinBranches = [
       "garlic/mpi+send+omp+fork"
  ];

  # Initial variable configuration
  varConf = {
    gitBranch = [
      "garlic/tampi+isend+oss+task"
    ] ++ optionals (enableExtended) ([
      "garlic/tampi+send+oss+task"
      "garlic/mpi+send+omp+task"
      "garlic/mpi+send+oss+task"
    ] ++ forkJoinBranches);

    blocksize = if (enableExtended)
      then range2 1 16
      else [ 2 ];

    n = [ {nx=100; nz=100; ny=8000;} ];

    nodes = range2 1 16;
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    expName = "fwi-ss";
    unitName = "${expName}"
    + "-nodes${toString nodes}"
    + "-bs${toString blocksize}"
    + "-${toString gitBranch}";

    inherit (machineConfig) hw;
    inherit (c) gitBranch blocksize;
    inherit (c.n) nx ny nz;

    fwiInput = bsc.apps.fwi.input.override {
      inherit (c.n) nx ny nz;
    };

    # Other FWI parameters
    ioFreq = -1;

    # Repeat the execution of each unit several times
    loops = 10;

    # Resources
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = hw.socketsPerNode;
    nodes = c.nodes;
    qos = "debug";
    time = "02:00:00";
    jobName = unitName;

    enableCTF = false;

    # Enable permissions to write in the local storage
    extraMounts = [ fs.local.temp ];

  };

  # Returns true if the given config is in the forkJoinBranches list
  isForkJoin = c: any (e: c.gitBranch == e) forkJoinBranches;

  # Set the blocksize to null for the fork join branch
  fixBlocksize = c: if (isForkJoin c) then (c // { blocksize = null; }) else c;

  # Compute the array of configurations
  allConfigs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  # The unique function ensures that we only run one config for the fork
  # join branch, even if we have multiple blocksizes.
  configs = unique (map fixBlocksize allConfigs);

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;
    pre = ''
      CDIR=$(pwd)
      EXECDIR="${fs.local.temp}/out/$GARLIC_USER/$GARLIC_UNIT/$GARLIC_RUN"
      mkdir -p "$EXECDIR"
      cd "$EXECDIR"
      ln -fs ${conf.fwiInput}/InputModels InputModels || true
    '' + optionalString (conf.enableCTF) ''
      export NANOS6_CONFIG_OVERRIDE="version.instrument=ctf"
    '';
    argv = [
      "${conf.fwiInput}/fwi_params.txt"
      "${conf.fwiInput}/fwi_frequencies.txt"
    ]
    ++ optional (isForkJoin conf) conf.blocksize
    ++ [
      "-1" # Fordward steps
      "-1" # Backward steps
      conf.ioFreq # Write/read frequency
    ];
    post = ''
      rm -rf Results || true
    '' + optionalString (conf.enableCTF) ''
      mv trace_* "$CDIR"
    '';
  };

  apps = bsc.garlic.apps;

  # FWI program
  program = {nextStage, conf, ...}: apps.fwi.solver.override {
    inherit (conf) gitBranch fwiInput;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
