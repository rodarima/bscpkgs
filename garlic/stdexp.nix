{
  stdenv
, config
, stages
, targetMachine
, garlicTools
, bsc
, writeTextFile
, runCommandLocal
, python
, pp
}:

with stdenv.lib;
with garlicTools;

let
  machineConf = targetMachine.config;
in
rec {
  /* Takes a list of units and builds an experiment, after executing the
  trebuchet, runexp and isolate stages. Returns the trebuchet stage. */
  buildTrebuchet = units:
  let
    trebuchet = stages.trebuchet {
      inherit (machineConf) nixPrefix sshHost;
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
  in trebuchet // rec {
    result = pp.store {
      trebuchet=trebuchet;
      experiment=trebuchet.experiment;
    };
    timetable = pp.timetable result;
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
      } //
      # However, if the experiment contains a reservation, that takes priority
      # over the one set in the ~/.config/nixpkgs/config.nix file. Add other
      # options if they are defined as well.
      optionalInherit [ "reservation" "time" "qos" ] conf //
      # Finally, add all the other required parameters
      {
        inherit nextStage nixPrefix;
        # These sbatch options are mandatory
        inherit cpusPerTask ntasksPerNode nodes jobName;
        exclusive = true;
      }
    );

    control = {nextStage, conf, ...}: stages.control {
      inherit (conf) loops;
      inherit nextStage;
    };

    srun = {nextStage, conf, preSrun ? "", postSrun ? "", ...}: (
      assert (assertMsg (!(conf ? cpuBind))
        "cpuBind is no longer available in the standard srun stage");
      stages.srun {
        inherit (conf) nixPrefix;
        inherit nextStage preSrun postSrun;

        # Binding is set to cores always
        cpuBind = "cores,verbose";
      }
    );

    isolate = {nextStage, conf, ...}: stages.isolate (
      (
        if (conf ? extraMounts) then { inherit (conf) extraMounts; }
        else {}
      ) //
      {
        inherit (conf) nixPrefix clusterName;
        inherit nextStage;
      }
    );

    baywatch = {nextStage, ...}: stages.baywatch {
      inherit nextStage;
    };
  };

  stdPipelineOverride = {overrides ? {}}:
  let
    stages = stdStages // overrides;
  in
    with stages; [ sbatch isolate control srun isolate baywatch ];


  stdPipeline = stdPipelineOverride {};

  replaceMpi = customMpi: bsc.extend (self: super: {
    mpi = customMpi;
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

  # Runs a python script and the standard output is directly imported as
  # nix code
  printPython = code:
    let
      p = writeTextFile {
        name = "python-script";
        text = ''
          from math import *
          ${code}
        '';
      };
    in
      import (runCommandLocal "a" { buildInputs = [ python ]; } ''
        python ${p} > $out'');
}
