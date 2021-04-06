{
  stdenv
, cc
, nanos6
, mcxx
, mpi
, tampi
, gitBranch ? "garlic/seq"
, gitCommit ? null
, garlicTools
}:

let
  gitSource = garlicTools.fetchGarlicApp {
    appName = "hpcg";
    inherit gitCommit gitBranch;
    gitTable = import ./git-table.nix;
  };
in
  stdenv.mkDerivation rec {
    name = "hpcg";

    inherit (gitSource) src gitBranch gitCommit;

    buildInputs = [
      cc nanos6 mcxx mpi tampi
    ];

    makeFlags = [
      "CC=${cc.CC}"
      "CXX=${cc.CXX}"
    ];

    enableParallelBuilding = true;

    installPhase = ''
      mkdir -p $out/bin
      cp bin/* $out/bin/
    '';

    programPath = "/bin/xhpcg";

    hardeningDisable = [ "all" ];
  }
