{
  stdenv
, mpi
, gfortran
, tampi
, nanos6
, mcxx
, gitBranch ? "garlic/mpi+isend+seq"
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "ifsker";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/garlic/apps/ifsker.git";
    ref = gitBranch;
  };

  buildInputs = [ tampi mpi nanos6 mcxx gfortran ];

  preferLocalBuild = true;

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

}
