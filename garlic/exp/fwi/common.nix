{
  stdenv
, stdexp
, bsc
, stages
}:

with stdenv.lib;

# Common definitions used by fwi experiments
rec {

  branchesWithoutBlocksize = [
    "garlic/mpi+send+omp+fork"
    "garlic/mpi+send+seq"
  ];

  # Returns true if the given config is in the forkJoinBranches list
  needsBlocksize = c: ! any (e: c.gitBranch == e) branchesWithoutBlocksize;

  # Set the blocksize to null for the fork join branch
  fixBlocksize = c: if (needsBlocksize c) then c
    else (c // { blocksize = null; });

  # Generate the configs by filtering the unneded blocksizes
  getConfigs = {varConf, genConf}:
  let
    allConfigs = stdexp.buildConfigs { inherit varConf genConf; };
  in
    # The unique function ensures that we only run one config for the fork
    # join branch, even if we have multiple blocksizes.
    unique (map fixBlocksize allConfigs);

  getResources = {gitBranch, hw}:
  if (gitBranch == "garlic/mpi+send+seq") then {
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = hw.socketsPerNode;
  } else {
    cpusPerTask = 1;
    ntasksPerNode = hw.cpusPerNode;
  };

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;

    pre = ''
      CDIR=$(pwd)
      EXECDIR="${conf.tempDir}/out/$GARLIC_USER/$GARLIC_UNIT/$GARLIC_RUN"
      mkdir -p "$EXECDIR"
      cd "$EXECDIR"
      ln -fs ${conf.fwiInput}/InputModels InputModels || true
    '' + optionalString (conf.enableCTF) ''
      export NANOS6_CONFIG_OVERRIDE="version.instrument=ctf"
    '';

    argv = [
      "${conf.fwiInput}/fwi_params.txt"
      "${conf.fwiInput}/fwi_frequencies.txt"
    ] ++ optional (needsBlocksize conf) conf.blocksize ++ [
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
}
