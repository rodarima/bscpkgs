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

  srun = {nextStage, conf, ...}:
  let
    fwiParams = bsc.apps.fwi.params.override {
      inherit (conf) nx ny nz;
    };
  in
    stdexp.stdStages.srun {
      inherit nextStage conf;
      # Now we add some commands to execute before calling srun. These will
      # only run in one rank (the first in the list of allocated nodes)
      preSrun = ''
        export GARLIC_FWI_SRUNDIR=$(pwd)
        export GARLIC_FWI_EXECDIR="${conf.tempDir}/out/$GARLIC_USER/$GARLIC_UNIT/$GARLIC_RUN"
        mkdir -p "$GARLIC_FWI_EXECDIR"

        export GARLIC_FWI_PARAMS="${fwiParams}/fwi_params.txt"
        export GARLIC_FWI_FREQ="${fwiParams}/fwi_frequencies.txt"

        # We cannot change the working directory of srun, so we use a
        # subshell to ignore the cd
        (
          # Generate the input dataset
          >&2 echo "generating the input dataset"
          cd "$GARLIC_FWI_EXECDIR"
          ${fwiParams}/bin/ModelGenerator \
            -m "$GARLIC_FWI_PARAMS" "$GARLIC_FWI_FREQ"
        )
      '';

      postSrun = optionalString (conf.enableCTF) ''
        # Save the traces
        mv "$GARLIC_FWI_EXECDIR"/trace_* .
      '' + ''
        # Remove everything else
        rm -rf "$GARLIC_FWI_EXECDIR"
      '';
    };

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;

    # FIXME: FWI should allow the I/O directory to be specified as a
    # parameter
    pre = ''
      # Run fwi at the in a directory with fast local storage
      cd "$GARLIC_FWI_EXECDIR"

      echo >&2 "Current dir: $(pwd)"
      echo >&2 "Using PARAMS=$GARLIC_FWI_PARAMS and FREQ=$GARLIC_FWI_FREQ"
    '' + optionalString (conf.enableCTF) ''
      export NANOS6_CONFIG_OVERRIDE="version.instrument=ctf"
    '';

    argv = [
      ''"$GARLIC_FWI_PARAMS"''
      ''"$GARLIC_FWI_FREQ"''
    ] ++ optional (needsBlocksize conf) conf.blocksize ++ [
      "-1" # Fordward steps
      "-1" # Backward steps
      conf.ioFreq # Write/read frequency
    ];
  };

  apps = bsc.garlic.apps;

  # FWI program
  program = {nextStage, conf, ...}:
  let
    fwiParams = bsc.apps.fwi.params.override {
      inherit (conf) nx ny nz;
    };
  in
    apps.fwi.solver.override {
      inherit (conf) gitBranch;
      inherit fwiParams;
    };

  pipeline = stdexp.stdPipelineOverride {
    # Replace the stdandard srun stage with our own
    overrides = { inherit srun; };
  } ++ [ exec program ];
}
