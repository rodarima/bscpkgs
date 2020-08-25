{
  stdenv
}:

program:

stdenv.mkDerivation {
  inherit program;
  name = "${program.name}-control";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  dontPatchShebangs = true;
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!/bin/sh
    set -e
    for n in {1..30}; do
      $program/bin/run
    done
    EOF
    chmod +x $out/bin/run
  '';
}
