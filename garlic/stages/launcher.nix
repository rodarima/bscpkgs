{
  stdenv
}:

apps: # Each app must be unique

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
      target=$out/apps/$(basename $j)
      if [ -e $target ]; then
        echo "Duplicated app: $j"
        echo
        echo "Provided apps: "
        printf "%s\n" $apps
        echo
        exit 1
      fi
      ln -s $j $target
    done

    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!/bin/sh

    for j in $out/apps/*; do
      \$j/bin/run
    done
    EOF

    chmod +x $out/bin/run

    # Mark the launcher for upload
    touch $out/.upload-to-mn
  '';
}
