{
  stdenv
, bash
, perf
}:

{
  app
, perfArgs ? "record -a"
, program ? "bin/run"
}:

stdenv.mkDerivation {
  name = "${app.name}-perf";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!${bash}/bin/bash

    exec ${perf}/bin/perf ${perfArgs} ${app}/${program}
    EOF
    chmod +x $out/bin/run
  '';
}
