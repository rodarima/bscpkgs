{
  stdenv
, nodes
, gitBranch
}:

stdenv.mkDerivation rec {
  name = "creams-input";

  # src = /home/Computational/pmartin1/creams-simplified;

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/pmartin1/creams-simplified.git";
    ref = "${gitBranch}";
  };

  phases = [ "unpackPhase" "installPhase" ];
  
  installPhase = ''
    pushd SodTubeBenchmark
      bash gridScript.sh 0 0 $((${toString nodes}*48)) 0
    popd

    mkdir -p $out
    cp -a SodTubeBenchmark $out/
  '';
}
