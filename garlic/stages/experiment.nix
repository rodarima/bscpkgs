{
  stdenv
, lib
, garlicTools
}:

{
  units
}:

with lib;
with garlicTools;

let
  unitsString = builtins.concatStringsSep "\n"
    (map (x: "${stageProgram x}") units);

  unitsLinks = builtins.concatStringsSep "\n"
    (map (x: "ln -s ../${baseNameOf x} ${baseNameOf x}") units);
in
stdenv.mkDerivation {
  name = "experiment";
  phases = [ "installPhase" ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  inherit units;

  isExperiment = true;

  installPhase = ''
    cat > $out << EOF
    #!/bin/sh

    if [ -z "\$GARLIC_OUT" ]; then
      >&2 echo "experiment: GARLIC_OUT not defined, aborting"
      exit 1
    fi

    cd "\$GARLIC_OUT"

    export GARLIC_EXPERIMENT=$(basename $out)

    if [ -e "\$GARLIC_EXPERIMENT" ]; then
      >&2 echo "experiment: skipping, directory exists: \$GARLIC_EXPERIMENT"
      exit 0
    fi

    mkdir -p "\$GARLIC_EXPERIMENT"

    cd "\$GARLIC_EXPERIMENT"
    ${unitsLinks}

    >&2 echo "experiment: running \$GARLIC_EXPERIMENT"

    # This is an experiment formed by the following units:
    ${unitsString}
    EOF
    chmod +x $out
  '';
}
