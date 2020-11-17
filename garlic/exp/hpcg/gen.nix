{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, resultFromTrebuchet
}:

with stdenv.lib;
with builtins;
with garlicTools;

let
  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "${c.expName}.gen";
    unitName = "${expName}.n${toString n.x}";

    inherit (targetMachine.config) hw;
    # hpcg options
    cc = bsc.icc;
    mcxx = bsc.mcxx;
    nanos6 = bsc.nanos6;
    mpi = null; # TODO: Remove this for oss

    # Only the n and gitBranch options are inherited
    inherit (c) n gitBranch;

    # Repeat the execution of each unit 30 times
    loops = 1;

    # Resources
    qos = "debug";
    ntasksPerNode = 1;
    nodes = 1;
    time = "02:00:00";
    # task in one socket
    cpusPerTask = hw.cpusPerSocket;
    jobName = unitName;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    env = "NANOS6_DEPENDENCIES=discrete";
    argv = [
      "--nx=${toString n.x}"
      "--ny=${toString n.y}"
      "--nz=${toString n.z}"
      # The nblocks is ignored
      #"--nblocks=${toString nblocks}"
      # Store the results in the same directory
      "--store=."
    ];
  };

  program = {nextStage, conf, ...}: with conf;
  let
    customPkgs = stdexp.replaceMpi conf.mpi;
  in
    customPkgs.apps.hpcg.override {
      inherit cc nanos6 mcxx gitBranch;
    };

  pipeline = stdexp.stdPipeline ++ [ exec program ];

  genExp = configs: stdexp.genExperiment { inherit configs pipeline; };
    
  genInputLink = inputConfigs: {nextStage, conf, ...}:
  let
    # Compute the experiment that produces HPCG input matrix from the
    # configuration of this unit:
    configs = map genConf inputConfigs;
    inputTre = genExp configs;
    #inputExp = getExperimentStage inputTrebuchet;
    #inputExp = trace inputTrebuchet inputTrebuchet.nextStage;
    inputExp = getExperimentStage inputTre;
    # Then load the result. This is only used to ensure that we have the
    # results, so it has been executed.
    inputRes = resultFromTrebuchet inputTre;
    # We also need the unit, to compute the path.
    inputUnit = stages.unit {
      conf = genConf conf;
      stages = pipeline;
    };
    # Build the path:
    expName = baseNameOf (toString inputExp);
    unitName = baseNameOf (toString inputUnit);
    relPath = "../../${expName}/${unitName}/1";
  in stages.exec {
    inherit nextStage;
    env = ''
      # This line ensures that the results of the HPCG generation are complete:
      # ${inputRes}

      # Then we simply link the input result directory in "input"
      ln -s ${relPath} input
    '';
  };

in
  #{ inherit genConf genExp genInputLink; }
  genInputLink
