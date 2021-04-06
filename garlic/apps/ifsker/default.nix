{
  stdenv
, mpi
, gfortran
, tampi
, nanos6
, mcxx
, gitBranch ? "garlic/mpi+isend+seq"
, gitCommit ? null
, garlicTools
}:

with stdenv.lib;

let
  gitSource = garlicTools.fetchGarlicApp {
    appName = "ifsker";
    inherit gitCommit gitBranch;
    gitTable = import ./git-table.nix;
  };
in
  stdenv.mkDerivation rec {
    name = "ifsker";

    inherit (gitSource) src gitBranch gitCommit;

    buildInputs = [ tampi mpi nanos6 mcxx gfortran ];

    # Mercurium seems to fail when building with fortran in parallel
    enableParallelBuilding = false;

    # FIXME: Patch mcxx to use other directory than $HOME for the lock
    # files.
    preConfigure = ''
      export TAMPI_HOME=${tampi}

      # $HOME is required for the lock files by mcxx to compile fortran.
      # So we use the $TMPDIR to store them.
      export HOME=$TMPDIR
    '';

    makeFlags = [
      "-f" "Makefile.gcc"
    ];


    installPhase = ''
      mkdir -p $out/bin
      cp ${name} $out/bin/

      mkdir -p $out/etc
      cp -r data $out/etc/
      cp nanos6.toml $out/etc
    '';

    programPath = "/bin/${name}";

    hardeningDisable = [ "all" ];
  }
