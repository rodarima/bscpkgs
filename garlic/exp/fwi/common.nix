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
    cpusPerTask = 1;
    ntasksPerNode = hw.cpusPerNode;
  } else {
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = hw.socketsPerNode;
  };

  exec = {nextStage, conf, ...}:
  let
    fwiParams = bsc.apps.fwi.params.override {
      inherit (conf) nx ny nz;
    };
  in stages.exec {
    inherit nextStage;

    # FIXME: FWI should allow the I/O directory to be specified as a
    # parameter
    pre = ''
      FWI_SRUNDIR=$(pwd)
      FWI_EXECDIR="${conf.tempDir}/out/$GARLIC_USER/$GARLIC_UNIT/$GARLIC_RUN"
      FWI_PARAMS="${fwiParams}/fwi_params.txt"
      FWI_FREQ="${fwiParams}/fwi_frequencies.txt"

      # Run fwi in a directory with fast local storage
      mkdir -p "$FWI_EXECDIR"
      cd "$FWI_EXECDIR"

      # Only generate the input if we have the CPU 0 (once per node)
      if grep -o 'Cpus_allowed_list:[[:space:]]0' \
        /proc/self/status > /dev/null;
      then
        FWI_CAPTAIN=1
      fi

      if [ $FWI_CAPTAIN ]; then
        >&2 echo "generating the input dataset"
        ${fwiParams}/bin/ModelGenerator -m "$FWI_PARAMS" "$FWI_FREQ"
      fi

      echo >&2 "Current dir: $(pwd)"
      echo >&2 "Using PARAMS=$FWI_PARAMS and FREQ=$FWI_FREQ"
    '' + optionalString (conf.enableCTF) ''
      export NANOS6_CONFIG_OVERRIDE="version.instrument=ctf"
    '';

    argv = [
      ''"$FWI_PARAMS"''
      ''"$FWI_FREQ"''
    ] ++ optional (needsBlocksize conf) conf.blocksize ++ [
      "-1" # Fordward steps
      "-1" # Backward steps
      conf.ioFreq # Write/read frequency
    ];

    post = ''
      # Go back to the garlic out directory
      cd "$FWI_SRUNDIR"

      if [ $FWI_CAPTAIN ]; then
    '' + optionalString (conf.enableCTF) ''
        # FIXME: We should specify the path in the nanos6 config, so we
        # can avoid the race condition while they are generating the
        # traces
        sleep 3

        # Save the traces
        mv "$FWI_EXECDIR"/trace_* .
    '' + ''
        rm -rf "$FWI_EXECDIR"
      fi
    '';
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

  pipeline = stdexp.stdPipeline ++ [ exec program ];
}
