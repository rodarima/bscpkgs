{
  stdenv
, python3
, granul ? 9
, nprocx ? 1
, nprocy ? 1
, nprocz ? 1
, nx ? 20
, ny ? 20
, nz ? 7000
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

  gen = ./gen_grid.py;
in
  stdenv.mkDerivation rec {
    name = "creams-input";

    buildInputs = [ python3 ];

    inherit (gitSource) src gitBranch gitCommit;

    phases = [ "unpackPhase" "installPhase" ];

    installPhase = ''
      mkdir -p $out
      cp -a SodTubeBenchmark $out/

      python3 ${gen} \
        --npx ${toString nprocx} \
        --npy ${toString nprocy} \
        --npz ${toString nprocz} \
        --grain ${toString granul} \
        --nx ${toString nx} \
        --ny ${toString ny} \
        --nz ${toString nz} \
        > $out/SodTubeBenchmark/grid.dat
    '';
  }
