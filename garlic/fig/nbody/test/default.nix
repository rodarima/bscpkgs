{
  stdenv
, gnuplot
, jq
, experiments
, garlicTools
, getExpResult
, writeText
, rWrapper
, rPackages
}:

with garlicTools;
with stdenv.lib;

let
  experiment = builtins.elemAt experiments 0;
  expResult = getExpResult {
    garlicTemp = "/tmp/garlic-temp";
    trebuchetStage = experiment;
    experimentStage = getExperimentStage experiment;
  };

  customR = rWrapper.override {
    packages = with rPackages; [ tidyverse ];
  };

  plotScript = ./plot.R;

in stdenv.mkDerivation {
  name = "plot";
  buildInputs = [ jq gnuplot customR ];
  preferLocalBuild = true;
  dontPatchShebangs = true;

  inherit expResult;

  src = ./.;

  buildPhase = ''
    echo "using results ${expResult}"

    substituteAllInPlace plot.R

    for unit in ${expResult}/*/*; do
      name=$(basename $unit)
      log="$unit/stdout.log"
      conf="$unit/garlic_config.json"
      bs=$(jq .blocksize $conf)
      awk "/^time /{print $bs, \$2}" $log >> data.csv
    done

    Rscript plot.R
  '';

  installPhase = ''
    mkdir $out
    ln -s ${expResult} $out/result
    cp *.png $out/
    cp data.csv $out/
  '';
}
