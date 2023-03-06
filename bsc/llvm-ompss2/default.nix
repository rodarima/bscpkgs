{
  stdenv
, gcc
, nanos6
, clangOmpss2Unwrapped
, wrapCCWith
, llvmPackages
}:


let

  # We need to replace the lld linker from bintools with our linker just built,
  # otherwise we run into incompatibility issues when mixing compiler and linker
  # versions.
  bintools-unwrapped = llvmPackages.tools.bintools-unwrapped.override {
    lld = clangOmpss2Unwrapped;
  };
  bintools = llvmPackages.tools.bintools.override {
    bintools = bintools-unwrapped;
  };

  targetConfig = stdenv.targetPlatform.config;
  inherit gcc nanos6;
  cc = clangOmpss2Unwrapped;
in wrapCCWith {
  inherit cc bintools;
  extraBuildCommands = ''
    echo "-target ${targetConfig}" >> $out/nix-support/cc-cflags
    echo "-B${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-cflags
    echo "-L${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-ldflags
    echo "-L${gcc.cc.lib}/lib" >> $out/nix-support/cc-ldflags

    for dir in ${gcc.cc}/include/c++/*; do
      echo "-isystem $dir" >> $out/nix-support/libcxx-cxxflags
    done
    for dir in ${gcc.cc}/include/c++/*/${targetConfig}; do
      echo "-isystem $dir" >> $out/nix-support/libcxx-cxxflags
    done

    echo "--gcc-toolchain=${gcc}" >> $out/nix-support/cc-cflags

    echo "# Hack to include NANOS6_HOME" >> $out/nix-support/setup-hook
    echo "export NANOS6_HOME=${nanos6}" >> $out/nix-support/setup-hook

    wrap clang++  $wrapper $ccPath/clang++
  '';
}
