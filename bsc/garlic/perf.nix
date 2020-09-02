{
  stdenv
, bash
, perf
}:

{
  program
, perfArgs ? "record -a"
}:

stdenv.mkDerivation {
  name = "perfWrapper";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<EOF
    #!${bash}/bin/bash

    exec ${perf}/bin/perf ${perfArgs} ${program}
    EOF
    chmod +x $out
  '';
}
