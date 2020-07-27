{
  stdenv
, mpi
, fetchurl
, apps
}:

stdenv.mkDerivation {
  name = "garlic-experiments";
  preferLocalBuild = true;

  src = ./.;

  buildInputs = [] ++ apps;
  apps = apps;

  buildPhase = ''
    for app in $apps; do
      test -e $app/bin/run || (echo $app/bin/run not found; exit 1)
    done
  '';

  installPhase = ''
    mkdir -p $out/apps
    for app in $apps; do
      ln -s $app $out/apps/$(basename $app)
    done

    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!/bin/bash

    for app in $out/apps/*; do
      \$app/bin/run
    done
    EOF

    chmod +x $out/bin/run
  '';
}
