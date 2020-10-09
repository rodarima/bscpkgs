{
  stdenv
, garlicTools
}:

{
  nextStage
, env ? ""
, argv ? []
}:

with builtins;
with garlicTools;

let
  argvString = concatStringsSep " " (map (e: toString e) argv);
in
stdenv.mkDerivation {
  name = "exec";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh
    ${env}

    exec ${stageProgram nextStage} ${argvString}
    EOF
    chmod +x $out
  '';
}
