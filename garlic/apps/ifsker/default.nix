{
  stdenv
, mpi
, gfortran
, tampi
, nanos6
, mcxx
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "ifsker";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/ksala/ifsker.git";
    ref = "master";
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
    cp *.bin $out/bin/
  '';

  # TODO: Split the app into variants
  programPath = "/bin/03.ifsker.mpi.ompss2.tasks.bin";

}
