{
  stdenv
, bash
}:

{
  app
, outputDir ? "."
, program ? "bin/run"
}:

stdenv.mkDerivation {
  name = "${app.name}-statspy";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!${bash}/bin/bash

    mkdir -p ${outputDir}
    cat /proc/[0-9]*/stat | sort -n > ${outputDir}/statspy.\$(date +%s.%3N).begin
    ${app}/${program}
    cat /proc/[0-9]*/stat | sort -n > ${outputDir}/statspy.\$(date +%s.%3N).end

    EOF
    chmod +x $out/bin/run
  '';
}
