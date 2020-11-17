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
  varConf = with bsc; {
    nb = [ 1 2 4 8 ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "saiph.granularity";
    unitName = "${expName}.nbx-nby-nbz-${toString nbx}-${toString nby}-${toString nbz}";
    inherit (targetMachine.config) hw;

    # saiph options
    nbx = c.nb;
    nby = c.nb;
    nbz = c.nb;
    mpi = impi;
    gitBranch = "garlic/tampi+isend+oss+task+simd";

    # Repeat the execution of each unit 50 times
    loops = 50;

    # Resources
    qos = "debug";
    time = "00:30:00";
    ntasksPerNode = 1;
    nodes = 1;
    cpusPerTask = hw.cpusPerSocket;
    jobName = "${unitName}-${gitBranch}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    env = ''
      export OMP_NUM_THREADS=${toString hw.cpusPerSocket}
      export NANOS6_REPORT_PREFIX="#"
      export I_MPI_THREAD_SPLIT=1
      export ASAN_SYMBOLIZER_PATH=${bsc.clangOmpss2Unwrapped}/bin/llvm-symbolizer
    '';
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.saiph.override {
      inherit nbx nby nbz mpi gitBranch;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
