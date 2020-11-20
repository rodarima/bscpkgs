{
  stdenv
, garlicTools
}:

{
  nextStage
, env ? ""
, pre ? ""
, argv ? []
, post ? ""
}:

with builtins;
with garlicTools;

let
  argvString = concatStringsSep " " (map (e: toString e) argv);
  execMethod = if (post == "") then "exec " else "";
in
stdenv.mkDerivation {
  name = "exec";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<'EOF'
    #!/bin/sh
    ${env}

    ''+pre+''
    ${execMethod}${stageProgram nextStage} ${argvString}
    ''+post+''
    EOF
    chmod +x $out
  '';
}
