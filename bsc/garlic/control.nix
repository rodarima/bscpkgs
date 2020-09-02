{
  stdenv
}:

{
  program
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
    for n in {1..30}; do
      ${program}
    done
    EOF
    chmod +x $out
  '';
}
