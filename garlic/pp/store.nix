{
  stdenv
}:

{
  trebuchet,
  experiment
}:

with builtins;

let
  experimentName = baseNameOf (experiment);
  trebuchetName = baseNameOf (trebuchet);
in
  stdenv.mkDerivation {
    name = "resultTree";
    preferLocalBuild = true;

    phases = [ "installPhase" ];

    installPhase = ''
      echo "resultTree: searching for garlicd daemon..."
      if [ -e /garlic/run ]; then
        echo "resultTree: asking the daemon to run and fetch the experiment"

        echo ${trebuchet} >> /garlic/run
        echo "resultTree: waiting for experiment results..."
        res=$(cat /garlic/completed)

        if [ "$res" != "${trebuchet}" ]; then
          echo "resultTree: unknown trebuchet received"
          exit 1
        fi
      else
        echo "resultTree: garlicd not detected: /garlic/run not found"
        echo "resultTree: assuming results are already in /garlic"
      fi

      echo "resultTree: attempting to copy the results from /garlic ..."

      exp=/garlic/cache/${experimentName}

      if [ ! -e "$exp" ]; then
        echo "resultTree: $exp: not found"
        echo "resultTree: run the experiment and fetch the results running"
        echo "resultTree: the following command from the nix-shell"
        echo
        echo -e "\e[30;48;5;2mgarlic -RFv ${trebuchet}\e[0m"
        echo
        echo "resultTree: see garlic(1) for more details."
        echo "resultTree: cannot continue building $out, aborting"
        exit 1
      fi

      echo "resultTree: copying results from /garlic into the nix store..."

      mkdir -p $out
      cp -aL $exp $out/
      ln -s ${trebuchet} $out/trebuchet
      ln -s ${experiment} $out/experiment


      if [ -e /garlic/run ]; then
        echo "resultTree: removing temp files..."
        echo ${trebuchet} >> /garlic/wipe
        echo "resultTree: waiting confimation from daemon..."
        cat /garlic/completed > /dev/null
      else
        echo "resultTree: garlicd not detected: /garlic/run not found"
        echo "resultTree: ignoring temp files"
      fi

      echo "resultTree: successfully copied into the nix store"

      echo "  experiment: ${experiment}"
      echo "   trebuchet: ${trebuchet}"
      echo "  resultTree: $out"
    '';
  }
