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
      mkdir "\$n"
      cd "\$n"
      ${stageProgram nextStage}
      cd ..
    done
    EOF
    chmod +x $out
  '';
}
