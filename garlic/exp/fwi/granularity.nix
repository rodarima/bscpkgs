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
#      "garlic/tampi+send+oss+task"
#      "garlic/mpi+send+omp+task"
       "garlic/mpi+send+oss+task"
#      "garlic/mpi+send+seq"
#      "garlic/oss+task"
#      "garlic/omp+task"
#      "garlic/seq"
    ];

    blocksize = [ 1 2 4 8 16 32 ];
    #blocksize = [ 1 2 4 8 ];

    n = [
    	#{nx=500; nz=500; ny=1000; ntpn=1; nn=1;}
    	{nx=500; nz=500; ny=2000; ntpn=2; nn=1;}
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
    inherit (c.n) nx ny nz ntpn nn;

    fwiInput = bsc.apps.fwi.input.override {
      inherit (c.n) nx ny nz;
    };

    # Other FWI parameters
    ioFreq = -1;

    # Repeat the execution of each unit several times
    loops = 10;
    #loops = 1;

    # Resources
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = ntpn;
    nodes = nn;
    qos = "debug";
    time = "02:00:00";
    jobName = unitName;

    tracing = "no";

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
      CDIR=$PWD
      if [[ "${conf.tracing}" == "yes" ]]; then
          export NANOS6_CONFIG_OVERRIDE="version.instrument=ctf"
      fi
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
      conf.ioFreq # Write/read frequency
    ];
    post = ''
      rm -rf Results || true
      if [[ "${conf.tracing}" == "yes" ]]; then
          mv trace_* $CDIR
      fi
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
