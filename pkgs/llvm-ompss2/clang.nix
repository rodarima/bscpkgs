{
  llvmPackages_latest
, lib
, fetchFromGitHub
, cmake
, bash
, python3
, perl
, which
, elfutils
, libffi
, zlib
, pkg-config
, gcc # needed to set the rpath of libstdc++ for clang-tblgen
, enableDebug ? false
, useGit ? false
, gitUrl ? "ssh://git@bscpm04.bsc.es/llvm-ompss/llvm-mono.git"
, gitBranch ? "master"
, gitCommit ? "8c0d267c04d7fc3fb923078f510fcd5f4719a6cc"
}:

let
  stdenv = llvmPackages_latest.stdenv;

  release = rec {
    version = "2024.11";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "llvm";
      rev = "refs/tags/github-release-${version}";
      hash = "sha256-pF0qa987nLkIJPUrXh1srzBkLPfb31skIegD0bl34Kg=";
    };
  };

  git = rec {
    version = src.shortRev;
    src = builtins.fetchGit {
      url = gitUrl;
      ref = gitBranch;
      rev = gitCommit;
    };
  };

  source = if (useGit) then git else release;

in stdenv.mkDerivation rec {
  pname = "clang-ompss2";
  inherit (source) src version;

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
    llvmPackages_latest.lld
    elfutils
    libffi
    pkg-config
    zlib
    gcc.cc.lib # Required for libstdc++.so.6
  ];

  # Error with -D_FORTIFY_SOURCE=2, see https://bugs.gentoo.org/636604:
  # /build/source/compiler-rt/lib/tsan/dd/dd_interceptors.cpp:225:20:
  # error: redefinition of 'realpath'
  # Requires disabling the "fortify" set of flags, however, for performance we
  # disable all:
  hardeningDisable = [ "all" ];

  cmakeBuildType = if enableDebug then "Debug" else "Release";

  dontStrip = enableDebug;

  dontUseCmakeBuildDir = true;

  # Fix the host triple, as it has changed in a newer config.guess:
  # https://git.savannah.gnu.org/gitweb/?p=config.git;a=commitdiff;h=ca9bfb8cc75a2be1819d89c664a867785c96c9ba
  preConfigure = ''
    mkdir -p build
    cd build
    cmakeDir="../llvm"
    cmakeFlagsArray=(
      "-DLLVM_HOST_TRIPLE=${stdenv.targetPlatform.config}"
      "-DLLVM_TARGETS_TO_BUILD=host"
      "-DLLVM_BUILD_LLVM_DYLIB=ON"
      "-DLLVM_LINK_LLVM_DYLIB=ON"
      # Required to run clang-ast-dump and clang-tblgen during build
      "-DCMAKE_BUILD_RPATH=$PWD/lib:${zlib}/lib:${gcc.cc.lib}/lib"
      "-DLLVM_ENABLE_LLD=ON"
      "-DCMAKE_CXX_FLAGS_DEBUG=-g -ggnu-pubnames"
      "-DCMAKE_EXE_LINKER_FLAGS_DEBUG=-Wl,--gdb-index"
      "-DLLVM_LIT_ARGS=-sv --xunit-xml-output=xunit.xml"
      "-DLLVM_ENABLE_PROJECTS=clang;compiler-rt;lld"
      "-DLLVM_ENABLE_ASSERTIONS=ON"
      "-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON"
      "-DCMAKE_INSTALL_BINDIR=bin"
      "-DLLVM_ENABLE_ZLIB=FORCE_ON"
      "-DLLVM_ENABLE_LIBXML2=OFF"
      # Set the rpath to include external libraries (zlib) both on build and
      # install
      "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON"
      "-DCMAKE_INSTALL_RPATH=${zlib}/lib:${gcc.cc.lib}/lib"
      "-DLLVM_APPEND_VC_REV=ON"
      "-DLLVM_FORCE_VC_REVISION=${source.version}"
    )
  '';

# About "-DCLANG_DEFAULT_NANOS6_HOME=${nanos6}", we could specify a default
# nanos6 installation, but this is would require a recompilation of clang each
# time nanos6 is changed. Better to use the environment variable NANOS6_HOME,
# and specify nanos6 at run time.
}
