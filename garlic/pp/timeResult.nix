{
  stdenv
}:

inputResult:

stdenv.mkDerivation {
  name = "timeResult";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out
    cd ${inputResult}
    for unit in *-experiment/*-unit; do
      outunit=$out/$unit
      mkdir -p $outunit

      # Copy the unit config
      conf="$unit/garlic_config.json"
      cp "$conf" "$outunit/garlic_config.json"

      # Merge all runs in one single CSV file
      echo "run time" > $outunit/data.csv
      for r in $(cd $unit; ls -d [0-9]* | sort -n); do
        log="$unit/$r/stdout.log"
        awk "/^time /{print \"$r\", \$2}" $log >> $outunit/data.csv
      done
    done
  '';
}
