{
  stdenv
, bash
, writeText
}:

{
  stages
, conf
}:

with stdenv.lib;
with builtins;

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

  jsonConf = writeText "garlic_config.json" (builtins.toJSON conf);

  safeUnitName = replaceStrings ["/" "$"] ["_" "_"] conf.unitName;
  safeExpName = replaceStrings ["/" "$"] ["_" "_"] conf.expName;
in
  builtins.trace "evaluating unit ${conf.unitName}"
stdenv.mkDerivation {
  name = "unit";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  inherit desc;
  installPhase = ''
    cat > $out << EOF
    #!/bin/sh -e

    ${desc}

    if [ -z "\$GARLIC_OUT" ]; then
      >&2 echo "unit: GARLIC_OUT not defined, aborting"
      exit 1
    fi

    if [ -z "\$GARLIC_EXPERIMENT" ]; then
      >&2 echo "unit: GARLIC_EXPERIMENT not defined, aborting"
      exit 1
    fi

    if [ -z "\$GARLIC_INDEX" ]; then
      >&2 echo "unit: GARLIC_INDEX not defined, aborting"
      exit 1
    fi

    cd "\$GARLIC_OUT"

    # Set the experiment unit in the environment
    export GARLIC_UNIT=$(basename $out)

    # Create an index entry
    rm -f "\$GARLIC_INDEX/${safeUnitName}" \
      "\$GARLIC_INDEX/${safeExpName}" 

    ln -Tfs "../out/\$GARLIC_UNIT" \
      "\$GARLIC_INDEX/${safeUnitName}"

    ln -Tfs "../out/\$GARLIC_EXPERIMENT" \
      "\$GARLIC_INDEX/${safeExpName}"

    if [ -e "\$GARLIC_UNIT" ]; then
      >&2 echo "unit: skipping, already exists: \$GARLIC_UNIT"
      exit 0
    fi

    # And change the working directory
    mkdir \$GARLIC_UNIT
    cd \$GARLIC_UNIT

    # Copy the configuration for the unit to the output path
    cp ${jsonConf} garlic_config.json

    # Finally, execute the first stage:
    exec ${firstStage}
    EOF

    chmod +x $out
  '';
}
