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

    if [ -z "\$GARLIC_OUT" ]; then
      >&2 echo "GARLIC_OUT not defined, aborting"
      exit 1
    fi

    export GARLIC_EXPERIMENT=$(basename $out)
    echo "Running experiment \$GARLIC_EXPERIMENT"

    if [ -e "\$GARLIC_EXPERIMENT" ]; then
      >&2 echo "Already exists \$GARLIC_EXPERIMENT, aborting"
      exit 1
    fi

    mkdir -p "\$GARLIC_EXPERIMENT"
    cd "\$GARLIC_EXPERIMENT"

    # This is an experiment formed by the following units:
    ${unitsString}
    EOF
    chmod +x $out
  '';
}
