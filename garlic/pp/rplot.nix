{
  stdenv
, rWrapper
, rPackages
, fontconfig
, jq
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
  buildInputs = [ customR jq ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  phases = [ "installPhase" ];

  installPhase = ''
    export FONTCONFIG_PATH=${fontconfig.out}/etc/fonts
    mkdir -p $out
    cd $out
    ln -s ${dataset} input
    Rscript --vanilla ${script} ${dataset}
    jq -c .total_time input |\
      awk '{s+=$1} END {printf "%f\n", s/60}' > total_job_time_minutes
  '';
}
