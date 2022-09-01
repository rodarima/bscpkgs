{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
, inputTre
, n
, dram
, garlicTools
, resultFromTrebuchet
}:

with lib;
with garlicTools;

let
  # Initial variable configuration
  varConf = with bsc; { };

  inherit (targetMachine) fs;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "shuffle";
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

    # We need access to a fast shared filesystem to store the shuffled input
    # dataset
    extraMounts = [ fs.shared.fast ];
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf;
  let
    inputExp = inputTre.experiment;
    inputUnit = elemAt inputExp.units 0;
    unitName = baseNameOf (toString inputUnit);

    # We also need the result. This is only used to ensure that we have the
    # results, so it has been executed.
    inputRes = resultFromTrebuchet inputTre;

    #FIXME: We need a better mechanism to get the output paths
    inFile = "${fs.shared.fast}/out/$GARLIC_USER/${unitName}/1/seq.dat";
    outDir = "${fs.shared.fast}/out/$GARLIC_USER/$GARLIC_UNIT/$GARLIC_RUN";
    outFile = "${outDir}/shuffled.dat";

  in
    stages.exec {
      inherit nextStage;
      pre = ''
        # This line ensures that the previous results are complete:
        # ${inputRes}

        # Exit on error
        set -e

        # Ensure the input file exists
        if [ ! -f "${inFile}" ]; then
          echo "input file not found: ${inFile}"
          exit 1
        fi

        mkdir -p "${outDir}"

        # Copy the input as we are going to overwrite it
        cp "${inFile}" "${outFile}"
      '';
      argv = [ n dram outFile 16 64 ];
      post = ''
        # Link the output here
        ln -s "${outFile}" shuffled.dat
      '';
    };

  program = {...}:
    bsc.apps.bigsort.shuffle;

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  stdexp.genExperiment { inherit configs pipeline; }
