{
  stdenv
, stdexp
, bsc
, stages
, numactl
, garlicTools
}:

with stdenv.lib;
with garlicTools;

rec {
  getConfigs = {varConf, genConf}: stdexp.buildConfigs {
    inherit varConf genConf;
  };

  exec = {nextStage, conf, ...}: stages.exec
  (
    {
      inherit nextStage;
      argv = with conf; [ "-t" timesteps "-p" particles ];
    }
    # Use numactl to use the interleave policy if requested (default is
    # false)
    // optionalAttrs (conf.interleaveMem or false) {
      program = "${numactl}/bin/numactl --interleave=all ${stageProgram nextStage}";
    }
  );

  program = {nextStage, conf, ...}: bsc.garlic.apps.nbody.override {
    inherit (conf) blocksize gitBranch;
  };

  pipeline = stdexp.stdPipeline ++ [ exec program ];
}
