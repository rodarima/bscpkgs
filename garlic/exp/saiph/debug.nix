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
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "saiph";
    unitName = "${expName}-debug";

#    unitName = if (gitCommit == "3b52a616d44f4b86880663e2d951ad89c1dcab4f") 
#      then "${expName}-N${toString nodes}" + "-nblx${toString nblx}-nbly${toString nbly}" + "-par-init"
#      else  "${expName}-N${toString nodes}" + "-nblx${toString nblx}-nbly${toString nbly}" + "-seq-init";

    inherit (targetMachine.config) hw;

    # saiph options
    manualDist = 1;
    nbgx = 1;
    nbgy = 1;
    nbgz = 8;
    nblx = 1;
    nbly = 4;
    nblz = 96;
    nbltotal = 384;
    mpi = impi;
    gitBranch = "garlic/tampi+isend+oss+task+simd";
    gitCommit = "3fa116620f1c7fbd1127d785c8bdc5d2372837b3";
    #gitCommit = c.gitCommit; # if exp involves more than 1 commit
    #inherit (c) gitCommit;   # if exp fixes the commit

    # Repeat the execution of each unit 50 times
    loops = 1;

    # Resources
    qos = "debug";
    ntasksPerNode = hw.socketsPerNode;
    nodes = 4;
    cpusPerTask = hw.cpusPerSocket;
    jobName = "${unitName}";

    # Compile flags
    debugFlags = 1;
    asanFlags = 0;
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
    pre = ''
      ulimit -c unlimited
    '';
  };

  valgrind = {nextStage, ...}: stages.valgrind {
    inherit nextStage;
  };

  program = {nextStage, conf, ...}:
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.saiph.override {
      inherit (conf) manualDist nbgx nbgy nbgz nblx nbly nblz nbltotal mpi gitBranch gitCommit debugFlags asanFlags;
    };

  pipeline = stdexp.stdPipeline ++ [ exec valgrind program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
