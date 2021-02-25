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
          echo "processing unit=$unit run=$run"
          time=$(awk '/^ ?time /{print $2}' $run/stdout.log)
          if [ -z "$time" ]; then
            echo "error: cannot match \"time\" line"
            echo "check stdout log file: ${inputResult}/$exp/$unit/$run/stdout.log"
            exit 1
          fi
          start_time=$(cat $run/.garlic/total_time_start)
          end_time=$(cat $run/.garlic/total_time_end)
          total_time=$(($end_time - $start_time))
          jq -cn "{ exp:\"$exp\", unit:\"$unit\", config:inputs, time:$time, run:$run, total_time:$total_time }" $conf >> $out
        done
      done
    done
  '';
}
