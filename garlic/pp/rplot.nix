{
  stdenv
, rWrapper
, rPackages
, fontconfig
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
    packages = with rPackages; [ tidyverse viridis egg ] ++ extraRPackages;
  };

in stdenv.mkDerivation {
  name = "plot";
  buildInputs = [ customR ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  phases = [ "installPhase" ];

  installPhase = ''
    export FONTCONFIG_PATH=${fontconfig.out}/etc/fonts
    mkdir -p $out
    cd $out
    ln -s ${dataset} input
    Rscript --vanilla ${script} ${dataset}
  '';
}
