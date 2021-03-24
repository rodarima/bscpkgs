######################################################################################
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
#   Mesh distributed across third dimension to ensure contiguous communications
#     --> nbgx = 1, nbgy = 1
#   First dimension cannot be locally blocked (simd reasons)
#   Second and third dimension local blocking limited by local mesh size 
# 
######################################################################################

# Common packages, tools and options
{ 
  stdenv
, stdexp
, bsc
, targetMachine
, stages
}:

with stdenv.lib;

let

  #*** Variable configurations ***
  varConf = with bsc; {
    # Local blocks per dimension
    nbl1 = [ 1 2 3 4 6 12 24 48 96 ];
    nbl2 = [ 1 2 3 4 6 12 24 48 96 ];
  };

  #*** Generate the complete configuration for each unit ***
  genConf = with bsc; c: targetMachine.config // rec {

    # Experiment, units and job names 
    expName = "saiph-granularity";
    unitName = "${expName}-N${toString nodes}" + "nbg_${toString nbgx}-${toString nbgy}-${toString nbgz}" + "nbl_1-${toString nbly}-${toString nblz}";
    jobName = "${unitName}";

    # saiph options
    nodes = 1;
    enableManualDist = true; # allows to manually set nbg{x-y-z}
    nbgx = 1;
    nbgy = 1;
    nbgz = nodes*2;    # forcing distribution by last dim
    nblx = 1;          # simd reasons
    nbly = c.nbl1;     # takes values from varConf
    nblz = c.nbl2;     # takes values from varConf
    mpi = impi;
    gitBranch = "garlic/tampi+isend+oss+task+simd";
    gitCommit = "8052494d7dc62bef95ebaca9938e82fb029686f6";  # fix a specific commit
    rev = "0"; 

    # Repeat the execution of each unit 30 times
    loops = 30;

    # Resources
    inherit (targetMachine.config) hw;
    qos = "debug";
    ntasksPerNode = hw.socketsPerNode;   # MPI binded to sockets
    cpusPerTask = hw.cpusPerSocket;      # Using the 24 CPUs of each socket
  };

  #*** Compute the final set of configurations ***
  # Compute the array of configurations: cartesian product of all factors
  allConfigs = stdexp.buildConfigs {
    inherit varConf genConf;
  };
  # Filter to remove non-desired configurations:
  #   --> tasks/proc < 0.5
  #   --> nblz > 50
  configs = filter (el: if ((builtins.mul el.nbly el.nblz) < (builtins.mul 0.5 el.cpusPerTask) || el.nblz > 50) then false else true) allConfigs;

  #*** Sets the env/argv of the program ***
  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    env = ''
      export OMP_NUM_THREADS=${toString hw.cpusPerSocket}
    '';
  };

  #*** Configure the program according to the app ***
  program = {nextStage, conf, ...}:
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.saiph.override {
      inherit (conf) enableManualDist nbgx nbgy nbgz nblx nbly nblz mpi gitBranch gitCommit;
    };

  #*** Add stages to the pipeline ***
  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
	stdexp.genExperiment { inherit configs pipeline; }

