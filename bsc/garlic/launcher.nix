{
  stdenv
}:

apps:

stdenv.mkDerivation {
  name = "launcher";
  preferLocalBuild = true;

  buildInputs = [] ++ apps;
  apps = apps;
  phases = [ "installPhase" ];
  dontPatchShebangs = true;

  installPhase = ''
    mkdir -p $out/apps
    for j in $apps; do
      ln -s $j $out/apps/$(basename $j)
    done

    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!/bin/sh

    for j in $out/apps/*; do
      \$j/bin/run
    done
    EOF

    chmod +x $out/bin/run
  '';
}
