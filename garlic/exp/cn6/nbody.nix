{
  stdenv
, stdexp
, bsc
, pkgs
, targetMachine
, stages
, garlicTools
, writeText
, enableHWC ? false
}:

with stdenv.lib;
with garlicTools;

let
  # Initial variable configuration
  varConf = {
    nodes = [ 2 ];
  };

  machineConfig = targetMachine.config;

  genConf = c: targetMachine.config // rec {
    expName = "cn6-nbody";
    unitName = expName + "-nodes${toString nodes}";

    inherit (machineConfig) hw;

    # Parameters for nbody
    particles = 4 * 1024 * hw.cpusPerSocket;
    timesteps = 2;
    blocksize = 512;
    gitBranch = "garlic/tampi+isend+oss+task";

    loops = 1;

    # Resources
    cpusPerTask = hw.cpusPerSocket;
    ntasksPerNode = hw.socketsPerNode;
    nodes = c.nodes;

    qos = "debug";
    time = "02:00:00";

    jobName = unitName;
  };

  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  # Custom BSC packages
  bsc' = bsc.extend (self: super: {

    # For nanos6 we use my fork for distributed instrumentation at the
    # latest commit
    nanos6 = (super.nanos6Git.override {
      enableJemalloc = true;
    }).overrideAttrs (old: rec {

      src = builtins.fetchGit {
        url = "git@bscpm03.bsc.es:nanos6/forks/nanos6-fixes.git";
        ref = "distributed-instrumentation";
        rev = "cd5169532887839515b24de6a7409dca7044f109";
      };
      
      dontStrip = false;
      version = src.shortRev;

      # Disable all unused instrumentations for faster builds
      configureFlags = old.configureFlags ++ [
        "--disable-extrae-instrumentation"
        "--disable-lint-instrumentation"
        "--disable-graph-instrumentation"
        "--disable-stats-instrumentation"
        "--with-babeltrace2=${super.babeltrace2}"
      ];
    });

    # Use clang from master
    clangOmpss2Unwrapped = super.clangOmpss2Unwrapped.overrideAttrs (old: rec {
      version = src.shortRev;
      src = builtins.fetchGit {
        url = "ssh://git@bscpm03.bsc.es/llvm-ompss/llvm-mono.git";
        ref = "master";
        rev = "ce47d99d2b2b968c87187cc7818cc5040b082d6c";
      };
    });

    # Use mcxx from master
    mcxx = super.mcxxGit;

    # We also need the instrumented version of TAMPI
    tampi = super.tampiGit.overrideAttrs (old: rec {
      version = src.shortRev;
      #dontStrip = true;
      #NIX_CFLAGS = "-O0 -g";
      src = builtins.fetchGit {
        url = "ssh://git@bscpm03.bsc.es/interoperability/tampi.git";
        ref = "instrument";
        rev = "8cf0f7bc02a7195717f58cc6725aeabd0299f53b";
      };
    });
  });

  ctf = {nextStage, conf, ...}: let
    # Create the nanos6 configuration file
    nanos6ConfigFile = writeText "nanos6.toml" ''
      version.instrument = "ctf"
      turbo.enabled = false
      instrument.ctf.converter.enabled = true
      instrument.ctf.converter.fast = true
    '';

  in stages.exec {
    inherit nextStage;

    # And use it
    env = ''
      export NANOS6_CONFIG=${nanos6ConfigFile}

      # Add nanos6 binaries to the PATH
      export PATH="$PATH:${bsc'.nanos6}/bin"
    '';

    post = ''
      rank=$SLURM_PROCID
      tracedir=trace_nbody

      # Merge on rank 0 only
      if [ $rank != 0 ]; then
        exit 0;
      fi

      # Wait a bit for all ranks to finish the conversion
      sleep 5

      # Run the merger
      nanos6-mergeprv "$tracedir"
    '';
  };

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;
    argv = with conf; [
      "-t" timesteps
      "-p" particles
    ];
  };

  program = {nextStage, conf, ...}: bsc'.garlic.apps.nbody.override {
    inherit (conf) blocksize gitBranch;
  };

  pipeline = stdexp.stdPipeline ++ [ ctf exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
