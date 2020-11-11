{
  stdenv
, rWrapper
, rPackages
}:

{
# The two results to be compared
  dataset
, script
, extraRPackages ? []
}:

with stdenv.lib;

let
  customR = rWrapper.override {
    packages = with rPackages; [ tidyverse ] ++ extraRPackages;
  };

in stdenv.mkDerivation {
  name = "plot";
  buildInputs = [ customR ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out
    cd $out
    ln -s ${dataset} input.json
    Rscript --vanilla ${script} ${dataset}
  '';
}
