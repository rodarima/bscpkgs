{
  stdenv
, nixPrefix ? ""
}:

units:

with stdenv.lib;

let
  stageProgram = stage:
    if stage ? programPath
    then "${stage}${stage.programPath}" else "${stage}";

  unitsString = builtins.concatStringsSep "\n"
    (map (x: "${stageProgram x}") units);

  desc = builtins.concatStringsSep "\n"
  (map (x: ''
    #    ${x}
    ${x.desc}'') units);

in
stdenv.mkDerivation {
  name = "experiment";
  phases = [ "installPhase" ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  inherit units;
  inherit desc;

  installPhase = ''
    cat > $out << EOF
    #!/bin/sh

    ${desc}

    # This is an experiment formed by the following units:
    ${unitsString}
    EOF
    chmod +x $out
  '';
}
