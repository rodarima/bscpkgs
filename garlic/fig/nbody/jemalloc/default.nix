{
  stdenv
, gnuplot
, jq
, garlicTools
, resultFromTrebuchet
, writeText
, rWrapper
, rPackages

# The two results to be compared
, resDefault
, resJemalloc
}:

with garlicTools;
with stdenv.lib;

let
  customR = rWrapper.override {
    packages = with rPackages; [ tidyverse ];
  };

  plotScript = ./plot.R;

in stdenv.mkDerivation {
  name = "plot";
  buildInputs = [ jq gnuplot customR ];
  preferLocalBuild = true;
  dontPatchShebangs = true;

  inherit resDefault resJemalloc;

  src = ./.;

  buildPhase = ''
    echo default = ${resJemalloc}
    echo jemalloc = ${resJemalloc}

    substituteAllInPlace plot.R

    for unit in ${resDefault}/*/*; do
      name=$(basename $unit)
      log="$unit/stdout.log"
      conf="$unit/garlic_config.json"
      bs=$(jq .blocksize $conf)
      awk "/^time /{print \"default\", $bs, \$2}" $log >> data.csv
    done

    for unit in ${resJemalloc}/*/*; do
      name=$(basename $unit)
      log="$unit/stdout.log"
      conf="$unit/garlic_config.json"
      bs=$(jq .blocksize $conf)
      awk "/^time /{print \"jemalloc\", $bs, \$2}" $log >> data.csv
    done

    #Rscript plot.R
  '';

  installPhase = ''
    mkdir $out
    ln -s ${resJemalloc} $out/resJemalloc
    ln -s ${resDefault} $out/resDefault
    #cp *.png $out/
    cp *.csv $out/
  '';
}
