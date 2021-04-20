{
  stdenv
, impi
, mcxx
, icc
, tampi ? null
, gitBranch ? "garlic/mpi+isend+seq"
, gitCommit ? null
, garlicTools
}:

with stdenv.lib;

let
  gitSource = garlicTools.fetchGarlicApp {
    appName = "lulesh";
    inherit gitCommit gitBranch;
    gitTable = import ./git-table.nix;
  };
in
  stdenv.mkDerivation rec {
    name = "lulesh";

    inherit (gitSource) src gitBranch gitCommit;

    dontConfigure = true;

    preBuild = optionalString (tampi != null) "export TAMPI_HOME=${tampi}";

    #TODO: Allow multiple MPI implementations and compilers
    buildInputs = [
      impi
      icc
      mcxx
    ];

    enableParallelBuilding = true;

    #TODO: Can we build an executable named "lulesh" in all branches?
    installPhase = ''
      mkdir -p $out/bin
      find . -name 'lulesh*' -type f -executable -exec cp \{\} $out/bin/${name} \;
    '';
    programPath = "/bin/${name}";

  }
