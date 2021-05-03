{
  stdenv
}:

datasets:

with stdenv.lib;

stdenv.mkDerivation {
  name = "merged-dataset";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  inherit datasets;
  installPhase = ''
    mkdir -p $out
    n=1
    for d in $datasets; do
      ln -s $d $out/$n
      let n=n+1
      cat $d/dataset >> $out/dataset
    done
  '';
}
