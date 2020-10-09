{
  stdenv
, bash
}:

{
  stages
, conf
}:

with stdenv.lib;

let

  dStages = foldr (stageFn: {conf, prevStage, stages}: {
    conf = conf;
    prevStage = stageFn {nextStage=prevStage; conf=conf;};
    stages = [ (stageFn {nextStage=prevStage; conf=conf;}) ] ++ stages;
  })
    {conf=conf; stages=[]; prevStage=null;} stages;

  stageProgram = stage:
    if stage ? programPath
    then "${stage}${stage.programPath}" else "${stage}";

  linkStages = imap1 (i: s: {
    num = "${toString i}";
    name = "${toString i}-${baseNameOf s.name}";
    stage = s;
    programPath = stageProgram s;
  }) dStages.stages;

  desc = builtins.concatStringsSep "\n"
    (map (x: "#      ${x.stage}") linkStages);


  firstStage = (x: x.programPath) (elemAt linkStages 0);
in
stdenv.mkDerivation {
  name = "unit";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  inherit desc;
  installPhase = ''
    cat > $out << EOF
    #!/bin/sh -e

    ${desc}

    # Set the experiment unit in the environment
    export GARLIC_UNIT=$(basename $out)

    # And change the working directory
    mkdir \$GARLIC_UNIT
    cd \$GARLIC_UNIT

    # Finally, execute the first stage:
    exec ${firstStage}
    EOF

    chmod +x $out
  '';
}
