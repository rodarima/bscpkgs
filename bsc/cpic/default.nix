{
  stdenv
, libconfig
, nanos6
, llvm-ompss2
, mpi
, uthash
, overrideCC
, llvmPackages_10
, fftw
}:

with stdenv.lib;

let
  buildStdenv = overrideCC stdenv [ llvm-ompss2 ];
in
buildStdenv.mkDerivation rec {
  name = "cpic";

  src = "${builtins.getEnv "HOME"}/cpic";
#  src = builtins.fetchGit {
#    url = "https://github.com/rodarima/cpic";
##    rev = "73bd70448587f0925b89e24c8f17e412ea3958e6";
#    ref = "master";
#  };

#  patchPhase = ''
#    echo LD=$LD
#    echo CC=$CC
#    echo ===================================================
#    env
#    echo ===================================================
#    echo ${buildStdenv}
#    echo ===================================================
#  '';

  configurePhase = ''
    ls -l /
    export NANOS6_HOME="${nanos6}"
  '';

  enableParallelBuilding = true;

  buildInputs = [
    libconfig
    nanos6
    llvm-ompss2
    mpi
    uthash
    llvmPackages_10.bintools
    fftw
  ];
}
