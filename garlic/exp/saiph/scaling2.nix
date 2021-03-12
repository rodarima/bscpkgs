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
    #nbl = [ 1 2 4 8 16 32 64 ];
    nodes = [ 1 2 4 8 ];

    input = [
      { nblz=12 ; nbly=1; nbltotal=12 ; }
      { nblz=24 ; nbly=1; nbltotal=24 ; }
      { nblz=48 ; nbly=1; nbltotal=48 ; }
      { nblz=96 ; nbly=1; nbltotal=96 ; }

      { nblz=6 ;  nbly=2; nbltotal=12 ; }
      { nblz=12 ; nbly=2; nbltotal=24 ; }
      { nblz=24 ; nbly=2; nbltotal=48 ; }
      { nblz=48 ; nbly=2; nbltotal=96 ; }
      { nblz=96 ; nbly=2; nbltotal=192 ; }

      { nblz=3  ; nbly=4; nbltotal=12 ; }
      { nblz=6  ; nbly=4; nbltotal=24 ; }
      { nblz=12 ; nbly=4; nbltotal=48 ; }
      { nblz=24 ; nbly=4; nbltotal=96 ; }
      { nblz=48 ; nbly=4; nbltotal=192 ; }
      { nblz=96 ; nbly=4; nbltotal=384 ; }
    ];

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
    nbgz = nodes*2;
    nblx = 1;
    #nbly = c.nbl;
    #nblz = c.nbl;
    mpi = impi;
    gitBranch = "garlic/tampi+isend+oss+task+simd";
    #gitCommit = c.gitCommit; # if exp involves more than 1 commit
    gitCommit = "3fa116620f1c7fbd1127d785c8bdc5d2372837b3";
    #inherit (c) gitCommit;   # if exp fixes the commit
    inherit (c.input) nbly nblz nbltotal ;

    # Repeat the execution of each unit 50 times
    loops = 10;

    # Resources
    qos = "bsc_cs";
    ntasksPerNode = hw.socketsPerNode;
    nodes = c.nodes;
    cpusPerTask = hw.cpusPerSocket;
    jobName = "${unitName}";
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };
  #configs = filter (el: if (el.nbly == 24 && el.nblz == 4) && el.nodes == 4 then false else true) configsAll;

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
      inherit (conf) manualDist nbgx nbgy nbgz nblx nbly nblz nbltotal mpi gitBranch gitCommit;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
	stdexp.genExperiment { inherit configs pipeline; }


# last plot hash: f5xb7jv1c4mbrcy6d9s9j10msfz3kkj0-plot
