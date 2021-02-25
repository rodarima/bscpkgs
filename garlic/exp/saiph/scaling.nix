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
    nbl = [ 1 2 4 8 16 32 64 ];
    nodes = [ 1 2 4 8 ];
    #gitCommit = [ "3ecae7c209ec3e33d1108ae4783d7e733d54f2ca" "3b52a616d44f4b86880663e2d951ad89c1dcab4f" ];
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "saiph";
    unitName = "${expName}-N${toString nodes}" + "-nblx${toString nblx}-nbly${toString nbly}" + "-par-init-One-dimensionalDistribution";
#    unitName = if (gitCommit == "3b52a616d44f4b86880663e2d951ad89c1dcab4f") 
#      then "${expName}-N${toString nodes}" + "-nblx${toString nblx}-nbly${toString nbly}" + "-par-init"
#      else  "${expName}-N${toString nodes}" + "-nblx${toString nblx}-nbly${toString nbly}" + "-seq-init";

    inherit (targetMachine.config) hw;

    # saiph options
    manualDist = 1;
    nbgx = 1;
    nbgy = 1;
    nbgz = nodes;
    nblx = 1;
    nbly = c.nbl;
    nblz = c.nbl;
    mpi = impi;
    gitBranch = "garlic/tampi+isend+oss+task+simd";
    #gitCommit = c.gitCommit; # if exp involves more than 1 commit
    #inherit (c) gitCommit;   # if exp fixes the commit

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
  #configs = filter (el: if el.nbly == 1 && el.nblz == 1 && el.nodes == 1 && el.gitCommit == "3b52a616d44f4b86880663e2d951ad89c1dcab4f" then false else true) configsAll;


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
      inherit (conf) manualDist nbgx nbgy nbgz nblx nbly nblz mpi gitBranch;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
