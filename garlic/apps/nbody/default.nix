{
  stdenv
, cc
, mpi ? null
, tampi ? null
, mcxx ? null
, cflags ? null
, gitBranch ? "garlic/seq"
, gitCommit ? null
, blocksize ? 2048
, garlicTools
}:

assert !(tampi != null && mcxx == null);

with stdenv.lib;

let
  gitSource = garlicTools.fetchGarlicApp {
    appName = "nbody";
    inherit gitCommit gitBranch;
    gitTable = import ./git-table.nix;
  };
in
  stdenv.mkDerivation rec {
    name = "nbody";

    inherit (gitSource) src gitBranch gitCommit;

    programPath = "/bin/nbody";

    buildInputs = [
      cc
    ]
    ++ optional (mpi != null) mpi
    ++ optional (tampi != null) tampi
    ++ optional (mcxx != null) mcxx;

    preBuild = (if cflags != null then ''
      makeFlagsArray+=(CFLAGS="${cflags}")
    '' else "");

    makeFlags = [
      "CC=${cc.CC}"
      "BS=${toString blocksize}"
    ]
    ++ optional (tampi != null) "TAMPI_HOME=${tampi}";

    dontPatchShebangs = true;

    installPhase = ''
      echo ${tampi}
      mkdir -p $out/bin
      cp nbody* $out/bin/${name}
    '';

    hardeningDisable = [ "all" ];
  }
