{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, n # must be a string
, dram # must be a string
, strace
}:

with stdenv.lib;

# Ensure the arguments are strings, to avoid problems with large numbers
assert (isString n);
assert (isString dram);

let
  # Initial variable configuration
  varConf = with bsc; { };

  inherit (targetMachine) fs;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "genseq";
    unitName = "${expName}.n${n}.dram${dram}";
    inherit (targetMachine.config) hw;
    inherit n dram;

    # Don't repeat
    loops = 1;

    # Resources
    qos = "debug";
    ntasksPerNode = 1;
    nodes = 1;
    time = "01:00:00";
    cpusPerTask = hw.cpusPerNode;
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf;
  let
    #FIXME: We need a better mechanism to get the output paths
    outDir = "${fs.shared.fast}/out/$GARLIC_USER/$GARLIC_UNIT/$GARLIC_RUN";
    outFile = "${outDir}/seq.dat";
  in
    stages.exec {
      inherit nextStage;
      pre = ''
        mkdir -p "${outDir}"
      '';
      argv = [ n dram outFile ];
      post = ''
        # Link the output here
        ln -s "${outFile}" seq.dat
      '';
    };

  program = {...}: bsc.apps.bigsort.genseq;

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
