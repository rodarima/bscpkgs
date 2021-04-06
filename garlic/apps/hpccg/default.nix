{
  stdenv
, icc
, mpi ? null
, tampi ? null
, mcxx ? null
, gitBranch ? "garlic/mpi+isend+seq"
, gitCommit ? null
, garlicTools
}:

assert !(tampi != null && mcxx == null);

with stdenv.lib;

let
  gitSource = garlicTools.fetchGarlicApp {
    appName = "hpccg";
    inherit gitCommit gitBranch;
    gitTable = import ./git-table.nix;
  };
in
  stdenv.mkDerivation rec {
    name = "hpccg";

    inherit (gitSource) src gitBranch gitCommit;

    programPath = "/bin/test_HPCCG-mpi.exe";

    buildInputs = [
      icc
    ]
    ++ optional (mpi != null) mpi
    ++ optional (tampi != null) tampi
    ++ optional (mcxx != null) mcxx;

    # The hpccg app fails to compile in parallel. Makefile must be fixed before.
    enableParallelBuilding = false;

    makeFlags = [
      "USE_MPI=-DUSING_MPI"
    ]
    ++ optional (tampi != null) "TAMPI_HOME=${tampi}";

    dontPatchShebangs = true;

    installPhase = ''
      echo ${tampi}
      mkdir -p $out/bin
      cp test_HPCCG-mpi.exe $out/bin
    '';

    hardeningDisable = [ "all" ];
  }
