{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, removeOutput ? true
, resultFromTrebuchet
, inputTre
}:

with stdenv.lib;

let
  varConf = { }; # Not used

  inherit (targetMachine) fs;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "bigsort";
    unitName = "${expName}.bs${toString bs}";
    inherit (targetMachine.config) hw;

    # bigsort options
    n = 1024 * 1024 * 1024 / 8; # In longs (?)
    bs = n; # In bytes
    pageSize = bs / 2; # In bytes (?)
    cc = bsc.icc;
    mpi = bsc.impi;
    gitBranch = "garlic/mpi+send+omp+task";

    # Repeat the execution of each unit 30 times
    loops = 1;

    # Resources
    qos = "debug";
    ntasksPerNode = 1;
    nodes = 1;
    time = "01:00:00";
    # All CPUs of the socket to each task
    cpusPerTask = hw.cpusPerSocket;
    jobName = "bigsort-${toString n}-${toString bs}-${gitBranch}";

    # Load the dataset from the same fs where it was stored in the shuffle
    # step. Also we use a local temp fs to store intermediate results.
    extraMounts = [ fs.shared.fast fs.local.temp ];

    rev = 1;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: with conf;
  let
    inputExp = inputTre.experiment;
    unit = elemAt inputExp.units 0;
    expName = baseNameOf (toString inputExp);
    unitName = baseNameOf (toString unit);

    # We also need the result. This is only used to ensure that we have the
    # results, so it has been executed.
    inputRes = resultFromTrebuchet inputTre;

    #FIXME: We need a better mechanism to get the output paths
    inFile = "${fs.shared.fast}/out/$GARLIC_USER/${unitName}/1/shuffled.dat";
    outDir = "${fs.shared.fast}/out/$GARLIC_USER/$GARLIC_UNIT/$GARLIC_RUN";
    outFile = "${outDir}/sorted.dat";
    tmpDir = fs.local.temp;
  in
    stages.exec {
    inherit nextStage;
    pre = ''
      # This line ensures that the shuffled results are complete: nix needs to
      # compute the hash of the execution log to write the path here.
      # ${inputRes}

      # Exit on error
      set -e

      # Ensure the input file exists
      if [ ! -f "${inFile}" ]; then
        echo "input file not found: ${inFile}"
        exit 1
      fi

      # Create the output path
      mkdir -p ${outDir}

      # Verbose args:
      echo "INPUT  = ${inFile}"
      echo "OUTPUT = ${outFile}"
      echo "TMPDIR = ${tmpDir}"
    '';

    argv = [ n bs inFile outFile tmpDir pageSize ];

    # Optionally remove the potentially large output dataset
    post = ''
      # Link the output here
      ln -s "${outFile}" sorted.dat
    '' + optionalString (removeOutput) ''
      # Remove the sorted output
      stat "${outFile}" > "${outFile}.stat"
      echo "file removed to save space" > "${outFile}"
    '';
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.bigsort.sort.override {
      inherit cc mpi gitBranch;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

in

  #{ inherit configs pipeline; }
  stdexp.genExperiment { inherit configs pipeline; }
