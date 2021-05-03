{
  stdenv
, python3
, gzip
}:

{
  script,
  compress ? true
}:

tree:

stdenv.mkDerivation {
  name = "dataset";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  buildInputs = [ python3 gzip ];
  installPhase = ''
    mkdir -p $out
    ln -s ${tree} $out/tree
    ln -s ${script} $out/script

    COMPRESS_DATASET=${toString compress}

    if [ $COMPRESS_DATASET ]; then
      python $out/script $out/tree | gzip > $out/dataset.json.gz
      ln -s dataset.json.gz $out/dataset
    else
      python $out/script $out/tree > $out/dataset.json
      ln -s dataset.json $out/dataset
    fi
  '';
}
