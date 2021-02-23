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
    nb = [ 1 2 4 8 16 32 64 ];
    nodes = [ 1 2 4 ];
    gitCommit = [
      "3ecae7c209ec3e33d1108ae4783d7e733d54f2ca"
    ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "saiph";
    unitName = "${expName}-N${toString nodes}" +
      "-nbx${toString nbx}-nby${toString nby}";

    inherit (targetMachine.config) hw;

    # saiph options
    nbx = 1;
    nby = c.nb;
    nbz = c.nb;
    mpi = impi;
    gitBranch = "garlic/tampi+isend+oss+task+simd";
    inherit (c) gitCommit;

    # Repeat the execution of each unit 50 times
    loops = 10;

    # Resources
    qos = "bsc_cs";
    ntasksPerNode = 1;
    nodes = c.nodes;
    cpusPerTask = hw.cpusPerSocket;
    jobName = "${unitName}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    env = ''
      export OMP_NUM_THREADS=${toString hw.cpusPerSocket}
      export ASAN_SYMBOLIZER_PATH=${bsc.clangOmpss2Unwrapped}/bin/llvm-symbolizer
    '';
  };

  program = {nextStage, conf, ...}:
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.saiph.override {
      inherit (conf) nbx nby nbz mpi gitBranch gitCommit;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
