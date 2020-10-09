{
  stdenv
, nixpkgs
, pkgs
, stages
, machineConf
}:

with stdenv.lib;

let
  bsc = pkgs.bsc;
  w = runWrappers;
in
{
  /* Returns the path of the executable of a stage */
  stageProgram = stage:
    if stage ? programPath
    then "${stage}${stage.programPath}"
    else "${stage}";

  /* Takes a list of units and builds an experiment, after executing the
  trebuchet and the isolate stages. Returns the trebuchet stage. */
  buildExperiment = {units, conf, ...}: stage.trebuchet {
    inherit (machineConf) nixPrefix;
    nextStage = stage.isolate {
      inherit (machineConf) nixPrefix;
      nextStage = stage.experiment {
        inherit units;
      }
    }
  };

  sbatch = {nextStage, conf, ...}: with conf; w.sbatch (
    # Allow a user to define a custom reservation for the job in MareNostrum4,
    # by setting the garlic.sbatch.reservation attribute in the 
    # ~/.config/nixpkgs/config.nix file. If the attribute is not set, no
    # reservation is used. The user reservation may be overwritten by the
    # experiment, if the reservation is set like with nodes or ntasksPerNode.
    optionalAttrs (pkgs.config ? garlic.sbatch.reservation) {
      inherit (pkgs.config.garlic.sbatch) reservation;
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
}
