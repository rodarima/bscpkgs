#######################################################################
# Saiph, granularity experiment:
#
# App:Heat 3D - garlic/tampi+isend+oss+task+simd branch
# App details:
#   3D mesh of ~400*400*400 points
#   nbgx = global blocks in the X dimension
#   nbgy = global blocks in the Y dimension
#   nbgz = global blocks in the Z dimension
#     --> nbgx*nbgy*nbgz = global distributed blocks
#   nbly = local blocks in the Y dimension
#   nblz = local blocks in the Z dimension
#     --> nbly*nblz = local blocks (#tasks)
#   
# Granularity experiment configuration:
#   Single-core run
#   MPI binded to sockets: MPI procs = 2
#   Mesh distributed across third dimension to ensure contiguous
#   communications
#     --> nbgx = 1, nbgy = 1
#   First dimension cannot be locally blocked (simd reasons)
#   Second and third dimension local blocking limited by local mesh size 
# 
#######################################################################

# Common packages, tools and options
{ 
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
}:

with lib;
with garlicTools;

let

  # Variable configurations
  varConf = with targetMachine.config; {
    # Local blocks per dimension
    nblx = [ 1 ]; # SIMD
    nbly = range2 1 (hw.cpusPerNode * 8);
    nblz = [ 8 ];
    sizex = [ 3 ];
    gitBranch = [ "garlic/tampi+isend+oss+task+simd" ];
  };

  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {

    # Experiment, units and job names 
    expName = "saiph-granularity";
    unitName = "${expName}"
      + "-N${toString nodes}"
      + "-nbg.x${toString nbgx}.y${toString nbgy}.z${toString nbgz}"
      + "-nbl.x${toString nblx}.y${toString nbly}.z${toString nblz}";

    jobName = unitName;

    # saiph options
    totalTasks = ntasksPerNode * nodes;
    nodes = 1;
    enableManualDist = true; # allows to manually set nbg{x-y-z}
    nbgx = 1;
    nbgy = 1;
    nbgz = totalTasks; # forcing distribution by last dim

    inherit (c) nblx nbly nblz gitBranch sizex;

    blocksPerTask = nblx * nbly * nblz * 1.0;
    blocksPerCpu = blocksPerTask / cpusPerTask;

    # fix a specific commit
    gitCommit = "8052494d7dc62bef95ebaca9938e82fb029686f6";

    # Repeat the execution of each unit 10 times
    loops = 10;

    # Resources
    inherit (targetMachine.config) hw;
    qos = "debug";
    ntasksPerNode = hw.socketsPerNode; # MPI binded to sockets
    cpusPerTask = hw.cpusPerSocket; # Using the 24 CPUs of each socket
  };

  #*** Compute the final set of configurations ***
  # Compute the array of configurations: cartesian product of all
  # factors
  allConfigs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  # Filter to remove non-desired configurations:
  #   --> tasks/proc < 0.5
  #   --> nblz > 50
  isGoodConfig = c:
  let
    maxNblz = c.cpusPerTask * 2;
  in
    ! (c.blocksPerCpu < 0.5 || c.nblz > maxNblz);

  configs = filter (isGoodConfig) allConfigs;

  #*** Sets the env/argv of the program ***
  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;
    env = ''
      export OMP_NUM_THREADS=${toString conf.cpusPerTask}
    '';
  };

  #*** Configure the program according to the app ***
  program = {nextStage, conf, ...}: bsc.apps.saiph.override {
    inherit (conf) enableManualDist
      nbgx nbgy nbgz nblx nbly nblz
      sizex
      gitBranch gitCommit;

    L3SizeKB = conf.hw.cacheSizeKB.L3;
    cachelineBytes = conf.hw.cachelineBytes;
  };

  #*** Add stages to the pipeline ***
  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
