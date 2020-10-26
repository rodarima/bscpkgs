{
  stdenv
, garlicTools
}:

{
  nextStage
, loops ? 30
}:

with garlicTools;

stdenv.mkDerivation {
  name = "control";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  dontPatchShebangs = true;
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh
    for n in \$(seq 1 ${toString loops}); do
      echo "running \$n of ${toString loops}" > status
      mkdir "\$n"
      cd "\$n"
      ${stageProgram nextStage}
      cd ..
    done
    echo "completed" > status
    EOF
    chmod +x $out
  '';
}
