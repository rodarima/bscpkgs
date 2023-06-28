{
  stdenv
, fetchFromGitHub
, cmake
, lld
, bash
, python3
, perl
, which
, elfutils
, libffi
, zlib
, pkg-config
, enableDebug ? false
}:

stdenv.mkDerivation rec {
  version = "2023.05";
  pname = "clang-ompss2";

  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "llvm";
    rev = "refs/tags/github-release-${version}";
    sha256 = "sha256-AWkIfF3ZuYqbwkXt5L5cs+obl7aXuyYGVOVHMauD4Wk=";
  };

  enableParallelBuilding = true;
  isClang = true;

  passthru = {
    CC = "clang";
    CXX = "clang++";
  };

  isClangWithOmpss = true;

  nativeBuildInputs = [ zlib ];

  buildInputs = [
    which
    bash
    python3
    perl
    cmake
    lld
    elfutils
    libffi
    pkg-config
    zlib
  ];

  # Error with -D_FORTIFY_SOURCE=2, see https://bugs.gentoo.org/636604:
  # /build/source/compiler-rt/lib/tsan/dd/dd_interceptors.cpp:225:20:
  # error: redefinition of 'realpath'
  # Requires disabling the "fortify" set of flags, however, for performance we
  # disable all:
  hardeningDisable = [ "all" ];

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
      "-DLLVM_ENABLE_PROJECTS=clang;openmp;compiler-rt;lld"
      "-DLLVM_ENABLE_ASSERTIONS=${enableAssertions}"
      "-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON"
      "-DCMAKE_INSTALL_BINDIR=bin"
      "-DLLVM_ENABLE_ZLIB=FORCE_ON"
      "-DLLVM_ENABLE_LIBXML2=OFF"
    )

  '';

  # Workaround the problem with llvm-tblgen and missing zlib.so.1
  preBuild = ''
    export LD_LIBRARY_PATH=${zlib}/lib
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
