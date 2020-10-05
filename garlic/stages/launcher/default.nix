{
  stdenv
, nixPrefix ? ""
}:

apps: # Each app must be unique

stdenv.mkDerivation {
  name = "launcher";
  preferLocalBuild = true;

  buildInputs = [] ++ apps;
  apps = apps;
  phases = [ "unpackPhase" "patchPhase" "installPhase" ];
  dontPatchShebangs = true;

  src = ./.;

  inherit nixPrefix;

  patchPhase = ''
    substituteAllInPlace run
    substituteAllInPlace stage2
  '';

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
    install -m755 run $out/bin/run
    install -m755 stage2 $out/bin/stage2
    chmod +x $out/bin/*

    # Mark the launcher for upload
    touch $out/.upload-to-mn
    # And mark it as an experiment
    touch $out/.experiment
  '';
}
