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
, resFreeCpu
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

  src = ./.;

  buildPhase = ''
    echo default = ${resDefault}
    echo freeCpu = ${resFreeCpu}

    substituteAllInPlace plot.R
    sed -ie "s:@expResult@:$out:g" plot.R

    for unit in ${resDefault}/*/*; do
      name=$(basename $unit)
      log="$unit/stdout.log"
      conf="$unit/garlic_config.json"
      bs=$(jq .blocksize $conf)
      awk "/^time /{print \"default\", $bs, \$2}" $log >> data.csv
    done

    for unit in ${resFreeCpu}/*/*; do
      name=$(basename $unit)
      log="$unit/stdout.log"
      conf="$unit/garlic_config.json"
      bs=$(jq .blocksize $conf)
      awk "/^time /{print \"freeCpu\", $bs, \$2}" $log >> data.csv
    done

    Rscript plot.R
  '';

  installPhase = ''
    mkdir $out
    ln -s ${resFreeCpu} $out/resFreeCpu
    ln -s ${resDefault} $out/resDefault
    cp *.png $out/
    cp *.csv $out/
  '';
}
