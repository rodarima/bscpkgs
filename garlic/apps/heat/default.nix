{
  stdenv
, mpi
, tampi
, mcxx
, gitBranch ? "garlic/mpi+send+seq"
, gitCommit ? null
, garlicTools
}:

let
  gitSource = garlicTools.fetchGarlicApp {
    appName = "heat";
    inherit gitCommit gitBranch;
    gitTable = import ./git-table.nix;
  };
in
  stdenv.mkDerivation rec {

    name = "heat";

    inherit (gitSource) src gitBranch gitCommit;

    patches = [ ./print-times.patch ];

    buildInputs = [ mpi mcxx tampi ];

    programPath = "/bin/${name}";

    installPhase = ''
      mkdir -p $out/bin
      cp ${name} $out/bin/

      mkdir -p $out/etc
      cp heat.conf $out/etc/
    '';
  }
