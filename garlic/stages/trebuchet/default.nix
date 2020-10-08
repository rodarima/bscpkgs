{
  stdenv
, nixtools
}:

{
  program
, nixPrefix
, sshHost ? "mn"
, targetCluster ? "mn4"
, experiment ? ""
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
    num = "${toString i}";
    name = "${toString i}-${baseNameOf s.name}";
    stage = s;
    programPath = stageProgram s;
  }) dStages.stages;

  units = builtins.concatStringsSep "\n"
    (map (x: "#  ${x}") experiment.units);

  firstStage = (x: x.programPath) (elemAt linkStages 0);
in

stdenv.mkDerivation {
  name = "trebuchet";
  phases = [ "installPhase" ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh -e
    # Using the token @upload-to-mn@ we instruct the post-build hook to upload
    # this script and it's closure to the MN4 cluster, so it can run there.
    # Take a look at ${program}
    # to see what is being executed.

    # Executes the following experiment in MN4:
    #  ${experiment}

    # Which contains the following experiment units:
    ${units}

    nixtools=${nixPrefix}${nixtools}/bin
    runexp=\$nixtools/${targetCluster}/runexp

    >&2 echo "Launching \"\$runexp ${program}\" in MN4"
    ssh ${sshHost} \$runexp ${program}
    EOF
    chmod +x $out
  '';
}
