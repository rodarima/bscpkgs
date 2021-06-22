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
    nodes = [ 1 2 4 8 ];
  };

  machineConfig = targetMachine.config;

  genConf = c: targetMachine.config // rec {
    expName = "timediff";
    unitName = expName + "-nodes${toString nodes}";

    inherit (machineConfig) hw;

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
        url = "git@bscpm03.bsc.es:rarias/nanos6.git";
        ref = "rodrigo";
        rev = "5cbeabb4e0446c2c293cc3005f76e6139465caee";
      };
      
      dontStrip = false;
      version = src.shortRev;

      # Disable all unused instrumentations for faster builds
      configureFlags = old.configureFlags ++ [
        "--disable-extrae-instrumentation"
        "--disable-lint-instrumentation"
        "--disable-graph-instrumentation"
        "--disable-stats-instrumentation"
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
      dontStrip = true;
      NIX_CFLAGS = "-O0 -g";
      src = builtins.fetchGit {
        url = "ssh://git@bscpm03.bsc.es/rarias/tampi.git";
        ref = "instrument";
        rev = "6e4294299bf761a1cc31f4181d9479cefa1c7f3e";
      };
    });

    # We use the latest commit in master as src for cn6
    cn6Git = ((super.cn6.overrideAttrs (old: rec {
      version = src.shortRev;
      src = builtins.fetchGit {
        url = "ssh://git@bscpm03.bsc.es/rarias/cn6.git";
        ref = "master";
        rev = "1d23d01d60164b8641746d5a204128a9d31b9650";
      };
    })).override { enableTest = true; });

    cn6 = self.cn6Git;
  });


  ctf = {nextStage, conf, ...}: let
    # Create the nanos6 configuration file
    nanos6ConfigFile = writeText "nanos6.toml" ''
      version.instrument = "ctf"
      turbo.enabled = false
      instrument.ctf.converter.enabled = false
    '' + optionalString (enableHWC) ''
      hardware_counters.papi.enabled = true
      hardware_counters.papi.counters = [
        "PAPI_TOT_INS", "PAPI_TOT_CYC",
        "PAPI_L1_TCM", "PAPI_L2_TCM", "PAPI_L3_TCM"
      ]
    '';

  in stages.exec {
    inherit nextStage;

    # And use it
    env = ''
      export NANOS6_CONFIG=${nanos6ConfigFile}
    '';

    post = ''
      rank=$SLURM_PROCID
      tracedir=trace_timediff_mpi

      # Convert CTF trace to PRV
      ${bsc'.cn6}/bin/cn6 $tracedir/$rank

      # Merge on rank 0 only
      if [ $rank != 0 ]; then
        exit 0;
      fi

      # Wait a bit for all ranks to finish the conversion
      sleep 5

      # Run the merger
      ${bsc'.cn6}/bin/merge-prv $tracedir

      # We need some tools the path
      export PATH="$PATH:${bsc'.babeltrace2}/bin:${pkgs.ministat}/bin"

      ${bsc'.cn6}/bin/sync-err.sh $tracedir
    '';
  };

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;
    program = "${bsc'.cn6}/bin/timediff_mpi";
    argv = [ conf.cpusPerTask ];
  };

  pipeline = stdexp.stdPipeline ++ [ ctf exec ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
