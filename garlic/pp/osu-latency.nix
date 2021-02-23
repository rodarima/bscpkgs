{
  stdenv
, jq
}:

inputResult:

stdenv.mkDerivation {
  name = "osu-latency.json";
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
          awk '/^[0-9]+ +[0-9\.]+$/{print $1, $2}' $run/stdout.log | (
            while read -r size latency; do
              jq -cn "{ exp:\"$exp\", unit:\"$unit\", config:inputs, run:$run, \
                size:$size, latency:$latency }" $conf >> $out
            done)
        done
      done
    done
  '';
}
