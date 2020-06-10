{
  stdenv
, fetchgit
, cmake
, lld
, bash
, python3
, perl
, clang
, which
}:

stdenv.mkDerivation rec {
  version = "10.0.0";
  name = "llvm-ompss2-${version}";
  enableParallelBuilding = true;
  buildInputs = [ which clang bash python3 perl cmake lld ];
  #preConfigure = ''
  #  ls
  #  cmakeFlagsArray=(
  #    "-DCMAKE_C_COMPILER=mpicc"
  #    "-DCMAKE_CXX_COMPILER=mpic++"
  #  )
  #'';

  # FIXME: The setup script installs into /build/source/llvm-install
  configurePhase = ''
    mkdir llvm-build
    cd llvm-build
    env bash ../utils/OmpSs/setup-cmake.sh
  '';

  src = builtins.fetchGit {
    url = "git@bscpm02.bsc.es:llvm-ompss/llvm-mono.git";
    rev = "38e2e6aac04d40b6b2823751ce25f6b414f52263";
    ref = "master";
  };
}
