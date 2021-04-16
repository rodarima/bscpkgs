{
  stdenv
, garlicTools
}:

{
  nextStage
, loops ? 30
}:

with garlicTools;

stdenv.mkDerivation {
  name = "control";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  dontPatchShebangs = true;
  installPhase = ''
    cat > $out <<"EOF"
    #!/bin/sh -e

    function badexit() {
      errcode=$?
      if [ $errcode != 0 ]; then
        printf "exit %d\n" $errcode > "$basedir/status"
        echo "exiting with $errcode"
      fi

      echo 1 > "$basedir/done"
      exit $errcode
    }

    trap badexit EXIT

    basedir=$(pwd)
    loops=${toString loops}
    for n in $(seq 1 $loops); do
      export GARLIC_RUN="$n"
      echo "run $n/$loops" > status
      mkdir "$n"
      cd "$n"
      mkdir .garlic
      date +%s > .garlic/total_time_start
      ${stageProgram nextStage}
      date +%s > .garlic/total_time_end
      cd ..
    done
    echo "ok" > status
    EOF
    chmod +x $out
  '';
}
