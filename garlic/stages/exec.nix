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
, nixPrefix ? ""
, program ? null
}:

with builtins;
with garlicTools;

let
  argvString = concatStringsSep " " (map (e: toString e) argv);
  execMethod = if (post == "") then "exec " else "";
  programPath = if (program != null) then program else (stageProgram nextStage);
in
stdenv.mkDerivation {
  name = "exec";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<'EOF'
    #!/bin/sh -e
    ${env}

    ${pre}

    ${execMethod}${nixPrefix}${programPath} ${argvString}

    ${post}

    EOF
    chmod +x $out
  '';
}
