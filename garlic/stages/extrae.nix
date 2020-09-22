{
  stdenv
, bash
#, writeShellScriptBin
}:

{
  program
, configFile
, traceLib
, extrae
}:

#writeShellScriptBin "extraeWrapper" ''
#  export EXTRAE_HOME=${extrae}
#  export LD_PRELOAD=${extrae}/lib/lib${traceLib}trace.so:$LD_PRELOAD
#  export EXTRAE_CONFIG_FILE=${configFile}
#  exec ${program}
#''

stdenv.mkDerivation {
  name = "extrae";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
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
