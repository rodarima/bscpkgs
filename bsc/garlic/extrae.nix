{
  stdenv
, bash
, extrae
}:

{
  app
, traceLib ? "mpi"
, configFile
, program ? "bin/run"
}:

stdenv.mkDerivation {
  name = "${app.name}-extrae";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!${bash}/bin/bash

    export EXTRAE_HOME=${extrae}
    export LD_PRELOAD=${extrae}/lib/lib${traceLib}trace.so:$LD_PRELOAD
    export EXTRAE_CONFIG_FILE=${configFile}
    exec ${app}/${program}
    EOF
    chmod +x $out/bin/run
  '';
}
