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
  };

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "saiph.granularity";
    unitName = "${expName}.nbx-nby-nbz-${toString nbx}-${toString nby}-${toString nbz}.nsteps-${nsteps}";
    inherit (targetMachine.config) hw;

    # saiph options
    nbx = 1;
    nby = c.nb;
    nbz = c.nb;
    nsteps = 500;
    mpi = impi;
    gitBranch = "garlic/tampi+isend+omp+task+simd";

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    cachelineBytes = hw.cachelineBytes;
    qos = "debug";
    time = "02:00:00";
    ntasksPerNode = 1;
    nodes = 1;
    ntasksPerNode = hw.socketsPerNode;
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
      export ASAN_SYMBOLIZER_PATH=${bsc.clangOmpss2Unwrapped}/bin/llvm-symbolizer
    '';
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.saiph.override {
      inherit nbx nby nbz nsteps mpi gitBranch cachelineBytes;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
