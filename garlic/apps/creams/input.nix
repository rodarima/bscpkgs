{
  stdenv
, granul ? 0
, nprocz ? 0
, gitBranch ? "garlic/mpi+send+seq"
, gitCommit ? null
, garlicTools
}:

let
  gitSource = garlicTools.fetchGarlicApp {
    appName = "creams";
    inherit gitCommit gitBranch;
    gitTable = import ./git-table.nix;
  };
in
  stdenv.mkDerivation rec {
    name = "creams-input";

    inherit (gitSource) src gitBranch gitCommit;

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
