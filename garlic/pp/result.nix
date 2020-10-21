{
  stdenv
, garlicTools
, fetchExperiment
}:

{
  trebuchetStage
, experimentStage
, garlicTemp
}:

with garlicTools;

let
  experimentName = baseNameOf (toString experimentStage);
  fetcher = fetchExperiment {
    sshHost = "mn1";
    prefix = "/gpfs/projects/\\\$(id -gn)/\\\$(id -un)/garlic-out";
    garlicTemp = "/tmp/garlic-temp";
    inherit experimentStage trebuchetStage;
  };
in
  stdenv.mkDerivation {
    name = "result";
    preferLocalBuild = true;
    __noChroot = true;

    phases = [ "installPhase" ];

    installPhase = ''
      expPath=${garlicTemp}/${experimentName}
      if [ ! -e $expPath ]; then
        echo "The experiment ${experimentName} is missing in ${garlicTemp}."
        echo "Please fetch it and try again."
        echo "You can execute ${trebuchetStage} to run the experiment."
        echo "And then ${fetcher} to get the results."
        exit 1
      fi
      mkdir -p $out
      cp -a ${garlicTemp}/${experimentName} $out
    '';
  }
