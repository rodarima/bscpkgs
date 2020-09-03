{
  stdenv
}:

{
  program
, loops ? 30
}:

stdenv.mkDerivation {
  name = "control";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  dontPatchShebangs = true;
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh
    #set -e
    for n in {1..${toString loops}}; do
      ${program}
    done
    EOF
    chmod +x $out
  '';
}
