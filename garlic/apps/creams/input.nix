{
  stdenv
, granul ? 0
, nprocz ? 0
, gitBranch
}:

stdenv.mkDerivation rec {
  name = "creams-input";

  # src = /home/Computational/pmartin1/creams-simplified;
  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/pmartin1/creams-simplified.git";
    ref = "${gitBranch}";
  };

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  patchPhase = ''
    patchShebangs SodTubeBenchmark/gridScript.sh
  '';
  
  installPhase = ''
    pushd SodTubeBenchmark
      ./gridScript.sh 0 0 ${toString nprocz} ${toString granul}
    popd

    mkdir -p $out
    cp -a SodTubeBenchmark $out/
  '';
}
