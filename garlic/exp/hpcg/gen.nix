{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
}:

with stdenv.lib;
with builtins;
with garlicTools;

let
  # Generate the complete configuration for each unit
  genConf = c: targetMachine.config // rec {
    expName = "${c.expName}.gen";
    unitName = "${expName}.n${toString n.x}";

    inherit (targetMachine.config) hw;

    # Only the n and gitBranch options are inherited
    inherit (c) n nprocs disableAspectRatio nodes ntasksPerNode gitBranch;

    # Repeat the execution of each unit 30 times
    loops = 1;

    # Resources
    qos = "debug";
    # ntasksPerNode = hw.socketsPerNode;
    # nodes = 2;
    time = "00:30:00";
    # task in one socket
    cpusPerTask = hw.cpusPerSocket;
    jobName = unitName;
  };

  exec = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    argv = [
      "--nx=${toString conf.n.x}"
      "--ny=${toString conf.n.y}"
      "--nz=${toString conf.n.z}"
      "--npx=${toString conf.nprocs.x}"
      "--npy=${toString conf.nprocs.y}"
      "--npz=${toString conf.nprocs.z}"
      # nblocks and ncomms are ignored
      "--nblocks=1"
      "--ncomms=1"
      # Store the results in the same directory
      "--store=."
    ] ++ optional (conf.disableAspectRatio) "--no-ar=1";
  };

  program = {nextStage, conf, ...}: bsc.apps.hpcg.override {
    inherit (conf) gitBranch;
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
    inputRes = inputTre.result;
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
      # We use || true because all ranks will execute this and
      # the execution will fail
      ln -sf ${relPath} input || true
    '';
  };

in
  #{ inherit genConf genExp genInputLink; }
  genInputLink
