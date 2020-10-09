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
  trebuchet and the isolate stages. Returns the trebuchet stage. */
  buildExperiment = units: stages.trebuchet {
    inherit (machineConf) nixPrefix;
    nextStage = stages.isolate {
      inherit (machineConf) nixPrefix;
      nextStage = stages.experiment {
        inherit units;
      };
    };
  };

  /* Given an attrset of lists `var` and an attrset `fixed`, computes the
    cartesian product of all combinations of `var` and prepends `fixed`
    to each. */
  buildConfigs = {fixed, var}:
    map (c: fixed // c) (genConfigs var);

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
      time = "02:00:00";
      qos = "debug";
      jobName = "nbody-tampi";
      inherit nextStage nixPrefix nodes ntasksPerNode;
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

  stdStages = [
    sbatch
    isolate
    control
    srun
    isolate
  ];

  # FIXME: Remove this hack and allow custom nixpkgs
  bscOverlay = import ../overlay.nix;
  nixpkgs = import <nixpkgs>;
  genPkgs = newOverlay: nixpkgs {
    overlays = [
      bscOverlay
      newOverlay
    ];
  };
}
