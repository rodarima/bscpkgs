{
  stdenv
}:

trebuchet:

stdenv.mkDerivation {
  name = "launcher";
  preferLocalBuild = true;

  phases = [ "installPhase" ];

  installPhase = ''
    if [ ! -e /garlic/run ]; then
      echo "Missing /garlic/run, cannot continue"
      echo "Are you running the garlicd daemon?"
      echo
      echo "You can manually run the experiment and fetch the results with:"
      echo
      echo -e "\e[30;48;5;2mgarlic -RFv ${trebuchetStage}\e[0m"
      echo
      echo "See garlic(1) for more details."
      exit 1
    fi

    echo ${trebuchet} >> /garlic/run
    echo "Waiting for experiment results..."
    results=$(cat /garlic/completed)
    #ln -s $results $out
    echo -n "$results" > $out
  '';
}
