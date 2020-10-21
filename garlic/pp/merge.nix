{
  stdenv
}:

experiments:

with stdenv.lib;

stdenv.mkDerivation {
  name = "merge.json";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat ${concatStringsSep " " experiments} >> $out
  '';
}
