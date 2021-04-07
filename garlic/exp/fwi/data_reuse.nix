# This test compares a FWI version using poor data locality (+NOREUSE) versus
# the optimized version (used for all other experiments). Follows a pseudocode
# snippet illustrating the fundamental difference between version.
#
# NOREUSE
# ----------------------
# for (y) for (x) for (z)
#   computA(v[y][x][z]);
# for (y) for (x) for (z)
#   computB(v[y][x][z]);
# for (y) for (x) for (z)
#   computC(v[y][x][z]);
#
# Optimized version
# ----------------------
# for (y) for (x) for (z)
#   computA(v[y][x][z]);
#   computB(v[y][x][z]);
#   computC(v[y][x][z]);

{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
}:

with stdenv.lib;

let

  inherit (targetMachine) fs;

  # Initial variable configuration
  varConf = {
    gitBranch = [
       "garlic/mpi+send+oss+task"
       "garlic/mpi+send+oss+task+NOREUSE"
    ];

    blocksize = [ 1 2 4 8 ];

    n = [
    	{nx=300; ny=2000; nz=300;} # / half node
    ];
  };

# The c value contains something like:
# {
#   n = { nx=500; ny=500; nz=500; }
#   blocksize = 1;
#   gitBranch = "garlic/tampi+send+oss+task";
# }

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "fwi";
    unitName = "${expName}-test";
    inherit (machineConfig) hw;

    cc = icc;
    inherit (c) gitBranch blocksize;

    #nx = c.n.nx;
    #ny = c.n.ny;
    #nz = c.n.nz;

    # Same but shorter:
    inherit (c.n) nx ny nz;

    fwiInput = bsc.apps.fwi.input.override {
      inherit (c.n) nx ny nz;
    };

    # Repeat the execution of each unit several times
    loops = 10;
    #loops = 1;

    # Resources
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = 1;
    nodes = 1;
    qos = "debug";
    time = "02:00:00";
    jobName = unitName;

    # Enable permissions to write in the local storage
    extraMounts = [ fs.local.temp ];

  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;
    pre = ''
      #CDIR=$PWD
      #export NANOS6_CONFIG_OVERRIDE="version.instrument=ctf"
      EXECDIR="${fs.local.temp}/out/$GARLIC_USER/$GARLIC_UNIT/$GARLIC_RUN"
      mkdir -p $EXECDIR
      cd $EXECDIR
      ln -fs ${conf.fwiInput}/InputModels InputModels || true
    '';
    argv = [
      "${conf.fwiInput}/fwi_params.txt"
      "${conf.fwiInput}/fwi_frequencies.txt"
      conf.blocksize
      "-1" # Fordward steps
      "-1" # Backward steps
      "-1" # Write/read frequency
    ];
    post = ''
      rm -rf Results || true
      #mv trace_* $CDIR
    '';
  };

  apps = bsc.garlic.apps;

  # FWI program
  program = {nextStage, conf, ...}: apps.fwi.solver.override {
    inherit (conf) cc gitBranch fwiInput;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
