{
  stdenv
}:

{
  experimentStage
, trebuchetStage
}:

with builtins;

#assert typeOf experimentStage == "string";
#assert typeOf trebuchetStage == "string";

let
  # We cannot keep the context of the string when called from a derivation, as
  # they will produce a different resultTree derivation vs called from the
  # garlic script tool.
  #_experimentStage = unsafeDiscardStringContext experimentStage;
  #_trebuchetStage = unsafeDiscardStringContext trebuchetStage;

  experimentName = baseNameOf (experimentStage);
  trebuchetName = baseNameOf (trebuchetStage);
  garlicTemp = "/tmp/garlic";
in
  #assert hasContext _trebuchetStage == false;
  #assert hasContext _experimentStage == false;
  stdenv.mkDerivation {
    name = "resultTree";
    preferLocalBuild = true;
    __noChroot = true;

    phases = [ "installPhase" ];

    installPhase = ''
      exp=${garlicTemp}/${experimentName}

      if [ ! -e "$exp" ]; then
        echo "$exp: not found"
        echo "Run the experiment and fetch the results with:"
        echo
        #echo "  garlic -RF -t ${trebuchetStage}"
        echo -e "\e[30;48;5;2mgarlic -RF -t ${trebuchetStage}\e[0m"
        echo
        echo "cannot continue building $out, aborting"
        exit 1
      fi

      mkdir -p $out
      cp -aL $exp $out/
      ln -s ${trebuchetStage} $out/trebuchet
      ln -s ${experimentStage} $out/experiment
    '';
  }
