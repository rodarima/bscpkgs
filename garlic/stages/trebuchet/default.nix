{
  stdenv
, nixtools
}:

{
  program
, nixPrefix
, sshHost ? "mn"
, targetCluster ? "mn4"
}:

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

    nixtools=${nixPrefix}${nixtools}/bin
    runexp=\$nixtools/${targetCluster}/runexp

    >&2 echo "Launching \"\$runexp ${program}\" in MN4"
    ssh ${sshHost} \$runexp ${program}
    EOF
    chmod +x $out
  '';
}
