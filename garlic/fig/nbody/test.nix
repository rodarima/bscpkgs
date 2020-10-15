{
  stdenv
, gnuplot
, jq
, experiments
, garlicTools
, getExpResult
, writeText
}:

with garlicTools;
with stdenv.lib;

let
  experiment = builtins.elemAt experiments 0;
  expResult = getExpResult {
    garlicTemp = "/tmp/garlic-temp";
    inherit experiment;
  };
    #set xrange [16:1024]
  plotScript = writeText "plot.plg" ''
    set terminal png size 800,800
    set output 'out.png'
    set xrange [*:*]

    set nokey
    set logscale x 2
    set logscale y 2
    set grid

    set xlabel "blocksize"
    set ylabel "time (s)"

    plot filename using 1:2 with points
  '';

in stdenv.mkDerivation {
  name = "plot";
  phases = [ "installPhase" ];
  buildInputs = [ jq gnuplot ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  installPhase = ''
    mkdir $out
    for unit in ${expResult}/*/*; do
      name=$(basename $unit)
      log="$unit/stdout.log"
      conf="$unit/garlic_config.json"
      bs=$(jq .blocksize $conf)
      awk "/^time /{print $bs, \$2}" $log >> $out/data.csv
    done
    gnuplot -e "filename='$out/data.csv'" ${plotScript}
    cp out.png $out/out.png
  '';
  #installPhase = ''
  #  mkdir $out
  #  for unit in ${expResult}/*/*; do
  #    name=$(basename $unit)
  #    log="$unit/stdout.log"
  #    bs=$(jq .blocksize $log)
  #    awk "/^time /{print $bs, \$2}" $log >> $out/data.csv
  #  done
  #'';
    #gnuplot -e "filename='$out/data.csv'" ${plotScript}
}
