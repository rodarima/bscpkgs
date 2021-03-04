{
  stdenv
, fetchFromGitHub
, cmake
, lld
, bash
, python3
, perl
, which
, libelf
, libffi
, pkg-config
, enableDebug ? false
}:

stdenv.mkDerivation rec {
  version = "2020.11+d2d451fb";
  pname = "clang-ompss2";

  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "llvm";
    rev = "d2d451fb1a886b52d0ff95ec8484df7afa7a8132";
    sha256 = "1yrfxfp2wz3qpb7j39ra8kkjsqm328j611yrks8bjc86lscmp6yz";
  };

  enableParallelBuilding = true;
  isClang = true;

  passthru = {
    CC = "clang";
    CXX = "clang++";
  };

  isClangWithOmpss = true;

  buildInputs = [
    which
    bash
    python3
    perl
    cmake
    lld
    libelf
    libffi
    pkg-config
  ];

  # Error with -D_FORTIFY_SOURCE=2, see https://bugs.gentoo.org/636604:
  # /build/source/compiler-rt/lib/tsan/dd/dd_interceptors.cpp:225:20:
  # error: redefinition of 'realpath'
  hardeningDisable = [ "fortify" ];

  cmakeBuildType = if enableDebug then "Debug" else "Release";

  dontUseCmakeBuildDir = true;
  enableAssertions = if enableDebug then "ON" else "OFF";

  preConfigure = ''
    mkdir -p build
    cd build
    cmakeDir="../llvm"
    cmakeFlagsArray=(
      "-DLLVM_ENABLE_LLD=ON"
      "-DCMAKE_CXX_FLAGS_DEBUG=-g -ggnu-pubnames"
      "-DCMAKE_EXE_LINKER_FLAGS_DEBUG=-Wl,-gdb-index"
      "-DLLVM_LIT_ARGS=-sv --xunit-xml-output=xunit.xml"
      "-DLLVM_ENABLE_PROJECTS=clang;openmp;compiler-rt"
      "-DLLVM_ENABLE_ASSERTIONS=${enableAssertions}"
      "-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON"
    )
  '';

  # Remove support for GNU and Intel Openmp
  postInstall = ''
    rm $out/lib/libgomp*
    rm $out/lib/libiomp*
  '';

# About "-DCLANG_DEFAULT_NANOS6_HOME=${nanos6}", we could specify a default
# nanos6 installation, but this is would require a recompilation of clang each
# time nanos6 is changed. Better to use the environment variable NANOS6_HOME,
# and specify nanos6 at run time.
}
