{
  stdenv
, garlicTools
}:

{
  nextStage
, nixPrefix

# FIXME: These two should be specified in the configuration of the machine
, sshHost ? "mn"
, targetCluster ? "mn4"
}:

with garlicTools;

let
  program = stageProgram nextStage;
in
stdenv.mkDerivation {
  name = "trebuchet";
  phases = [ "installPhase" ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  inherit nextStage;
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh -e
    # Using the token @upload-to-mn@ we instruct the post-build hook to upload
    # this script and it's closure to the MN4 cluster, so it can run there.

    # This trebuchet launches:
    #  ${nextStage}
    #  ${nextStage.nextStage}
    #  ${nextStage.nextStage.nextStage}

    # Take a look at ${program}
    # to see what is being executed.
    ssh ${sshHost} ${nixPrefix}${program}
    EOF
    chmod +x $out
  '';
}
