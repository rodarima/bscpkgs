{
  stdenv
, bash
, extrae
, writeShellScriptBin
, jq
}:

{
  stages
, conf
, experimentName ? "run"
}:

with stdenv.lib;

let

  dStages = foldr (stageFn: {conf, prevStage, stages}: {
    conf = conf;
    prevStage = stageFn {stage=prevStage; conf=conf;};
    stages = [ (stageFn {stage=prevStage; conf=conf;}) ] ++ stages;
  })
    {conf=conf; stages=[]; prevStage=null;} stages;

  stageProgram = stage:
    if stage ? programPath
    then "${stage}${stage.programPath}" else "${stage}";

  linkStages = imap1 (i: s: {
    name = "${toString i}-${baseNameOf s.name}";
    path = stageProgram s;
  }) dStages.stages;

  createLinks = builtins.concatStringsSep "\n"
    (map (x: "ln -s ${x.path} $out/bin/${x.name}") linkStages);

  firstStageLink = (x: x.name) (elemAt linkStages 0);
in
stdenv.mkDerivation {
  name = "stagen";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  buildInputs = [ jq ];
  installPhase = ''
    mkdir -p $out/bin
    ${createLinks}
    ln -s ${firstStageLink} $out/bin/${experimentName}
    cat > $out/config.raw << EOF
    ${builtins.toJSON conf}
    EOF
    jq . $out/config.raw > $out/config.json
    rm $out/config.raw
  '';
}
