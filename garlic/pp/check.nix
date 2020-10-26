{
  stdenv
}:

resultTree:

stdenv.mkDerivation {
  name = "check";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    echo "checking result tree: ${resultTree}"
    cd ${resultTree}
    for exp in *-experiment; do
      cd ${resultTree}/$exp
      echo "$exp: checking units"
      for unit in *-unit; do
        cd ${resultTree}/$exp/$unit
        if [ ! -e status ]; then
          echo "missing $unit/status file, aborting"
          exit 1
        fi
        st=$(cat status)
        if [ "$st" != "completed" ]; then
          echo "unit $unit is not complete yet, aborting"
          exit 1
        fi
      done
      echo "$exp: execution complete"
    done
    ln -s $out ${resultTree}
  '';
}
