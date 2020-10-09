{
  stdenv
, garlicTools
}:

{
  nextStage
, configFile
, traceLib
, extrae
}:

with garlicTools;

let
  program = stageProgram nextStage;
in
  stdenv.mkDerivation {
    name = "extrae";
    phases = [ "installPhase" ];
    preferLocalBuild = true;
    dontPatchShebangs = true;
    installPhase = ''
      cat > $out <<EOF
      #!/bin/sh
      
      export EXTRAE_HOME=${extrae}
      export LD_PRELOAD=${extrae}/lib/lib${traceLib}trace.so:$LD_PRELOAD
      export EXTRAE_CONFIG_FILE=${configFile}
      exec ${program}
      EOF
      chmod +x $out
    '';
  }
