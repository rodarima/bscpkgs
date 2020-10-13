{
  stdenv
, config
, stages
, targetMachine
, garlicTools
}:

with stdenv.lib;
with garlicTools;

let
  machineConf = targetMachine.config;
in
rec {
  /* Takes a list of units and builds an experiment, after executing the
  trebuchet, runexp and isolate stages. Returns the trebuchet stage. */
  buildTrebuchet = units: stages.trebuchet {
    inherit (machineConf) nixPrefix;
    nextStage = stages.runexp {
      inherit (machineConf) nixPrefix;
      nextStage = stages.isolate {
        inherit (machineConf) nixPrefix;
        nextStage = stages.experiment {
          inherit units;
        };
      };
    };
  };

  /* Given an attrset of lists `varConf` and a function `genConf` that accepts a
  attrset, computes the cartesian product of all combinations of `varConf` calls
  genConf to produce the final list of configurations. */
  buildConfigs = {varConf, genConf}:
    map (c: genConf c) (genConfigs varConf);

  stdStages = {
    sbatch = {nextStage, conf, ...}: with conf; stages.sbatch (
      # Allow a user to define a custom reservation for the job in MareNostrum4,
      # by setting the garlic.sbatch.reservation attribute in the 
      # ~/.config/nixpkgs/config.nix file. If the attribute is not set, no
      # reservation is used. The user reservation may be overwritten by the
      # experiment, if the reservation is set like with nodes or ntasksPerNode.
      optionalAttrs (config ? garlic.sbatch.reservation) {
        inherit (config.garlic.sbatch) reservation;
      } // {
        exclusive = true;
        inherit nextStage nixPrefix nodes ntasksPerNode time qos jobName;
      }
    );

    control = {nextStage, conf, ...}: stages.control {
      inherit (conf) loops;
      inherit nextStage;
    };

    srun = {nextStage, conf, ...}: stages.srun {
      inherit (conf) nixPrefix cpuBind;
      inherit nextStage;
    };

    isolate = {nextStage, conf, ...}: stages.isolate {
      clusterName = machineConf.name;
      inherit (conf) nixPrefix;
      inherit nextStage;
    };
  };

  stdPipelineOverride = {overrides ? {}}:
  let
    stages = stdStages // overrides;
  in
    with stages; [ sbatch isolate control srun isolate ];


  stdPipeline = stdPipelineOverride {};

  # FIXME: Remove this hack and allow custom nixpkgs
  bscOverlay = import ../overlay.nix;
  nixpkgs = import <nixpkgs>;
  genPkgs = newOverlay: nixpkgs {
    overlays = [
      bscOverlay
      newOverlay
    ];
  };

  replaceMpi = mpi: genPkgs (self: super: {
    bsc = super.bsc // { inherit mpi; };
  });

  # Generate the experimental units
  genUnits = {configs, pipeline}: map (c: stages.unit {
    conf = c;
    stages = pipeline;
  }) configs;

  # Generate the complete experiment
  genExperiment = {configs, pipeline}: 
  let
    units = genUnits { inherit configs pipeline; };
  in
    buildTrebuchet units;
}
