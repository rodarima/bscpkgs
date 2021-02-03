{
  stdenv
, jq
}:

inputResult:

stdenv.mkDerivation {
  name = "timetable.json";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  buildInputs = [ jq ];
  installPhase = ''
    touch $out
    cd ${inputResult}
    for exp in *-experiment; do
      cd ${inputResult}/$exp
      for unit in *-unit; do
        cd ${inputResult}/$exp/$unit
        conf=garlic_config.json
        for run in $(ls -d [0-9]* | sort -n); do
          time=$(awk '/^ ?time /{print $2}' $run/stdout.log)
          if [ -z "$time" ]; then
            echo "error: cannot match \"time\" line"
            echo "check stdout log file: ${inputResult}/$exp/$unit/$run/stdout.log"
            exit 1
          fi
          jq -cn "{ exp:\"$exp\", unit:\"$unit\", config:inputs, time:$time, run:$run }" $conf >> $out
        done
      done
    done
  '';
}
