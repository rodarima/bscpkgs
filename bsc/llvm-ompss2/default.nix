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
, libelf
, libffi
, pkg-config
, enableDebug ? false
}:

stdenv.mkDerivation rec {
  version = "10.0.0";
  name = "llvm-ompss2-${version}";
  enableParallelBuilding = true;

  buildInputs = [
    which
    clang
    bash
    python3
    perl
    cmake
    lld
    libelf
    libffi
    pkg-config
  ];
  cmakeBuildType = if enableDebug then "Debug" else "Release";
  dontUseCmakeBuildDir = true;
  preConfigure = ''
    mkdir -p build
    cd build
    cmakeDir="../llvm"
    cmakeFlagsArray=(
      "-DLLVM_ENABLE_LLD=ON"
      "-DCMAKE_CXX_FLAGS_DEBUG=-g -ggnu-pubnames"
      "-DCMAKE_EXE_LINKER_FLAGS_DEBUG=-Wl,-gdb-index"
      "-DLLVM_LIT_ARGS=-sv --xunit-xml-output=xunit.xml"
      "-DLLVM_ENABLE_PROJECTS=clang;openmp"
      "-DLLVM_INSTALL_UTILS=ON"
      "-DLLVM_ENABLE_ASSERTIONS=ON"
    )
  '';

  src = builtins.fetchGit {
    url = "git@bscpm02.bsc.es:llvm-ompss/llvm-mono.git";
    rev = "38e2e6aac04d40b6b2823751ce25f6b414f52263";
    ref = "master";
  };
}
