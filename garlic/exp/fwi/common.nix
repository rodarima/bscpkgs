{
  stdenv
, stdexp
, bsc
, stages
}:

with stdenv.lib;

rec {

  # We split these into a separate group so we can remove the blocksize
  # later.
  forkJoinBranches = [ "garlic/mpi+send+omp+fork" ];

  # Returns true if the given config is in the forkJoinBranches list
  isForkJoin = c: any (e: c.gitBranch == e) forkJoinBranches;

  # Set the blocksize to null for the fork join branch
  fixBlocksize = c: if (isForkJoin c) then (c // { blocksize = null; }) else c;

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
    ] ++ optional (! isForkJoin conf) conf.blocksize ++ [
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
