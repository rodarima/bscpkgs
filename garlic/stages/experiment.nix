{
  stdenv
, garlicTools
}:

{
  units
}:

with stdenv.lib;
with garlicTools;

let
  unitsString = builtins.concatStringsSep "\n"
    (map (x: "${stageProgram x}") units);
in
stdenv.mkDerivation {
  name = "experiment";
  phases = [ "installPhase" ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  inherit units;

  installPhase = ''
    cat > $out << EOF
    #!/bin/sh

    # This is an experiment formed by the following units:
    ${unitsString}
    EOF
    chmod +x $out
  '';
}
