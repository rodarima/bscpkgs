{
  stdenv
, garlicTools
}:

{
  trebuchetStage
, experimentStage
, garlicTemp
}:

with garlicTools;

let
  experimentName = baseNameOf (toString experimentStage);
  garlicOut = "/mnt/garlic-out";
in
  stdenv.mkDerivation {
    name = "result";
    preferLocalBuild = true;
    __noChroot = true;

    phases = [ "installPhase" ];

    installPhase = ''
      expList=$(find ${garlicOut} -maxdepth 2 -name ${experimentName})

      if [ -z "$expList" ]; then
        echo "ERROR: missing results for ${experimentName}"
        echo "Execute it by running:"
        echo
        echo -e "  \e[30;48;5;2m${trebuchetStage}\e[0m"
        echo
        echo "cannot continue building $out, aborting"
        exit 1
      fi

      N=$(echo $expList | wc -l)
      echo "Found $N results: $expList"

      if [ $N -gt 1 ]; then
        echo 
        echo "ERROR: multiple results for ${experimentName}:"
        echo "$expList"
        echo
        echo "cannot continue building $out, aborting"
        exit 1
      fi

      exp=$expList
      repeat=1
      while [ 1 ]; do
        repeat=0
        cd $exp
        echo "$exp: checking units"
        for unit in *-unit; do
          cd $exp/$unit
          if [ ! -e status ]; then
            echo "$unit: no status"
            repeat=1
          else
            st=$(cat status)
            echo "$unit: $st"
            if [ "$st" != "completed" ]; then
              repeat=1
            fi
          fi
        done

        if [ $repeat -eq 0 ]; then
          break
        fi
        echo "waiting 10 seconds to try again"
        sleep 10
      done
      echo "$exp: execution complete"

      mkdir -p $out
      cp -aL $exp $out
    '';
  }
