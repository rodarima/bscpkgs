{
  stdenv
, gcc
, clangOmpss2Unwrapped
, wrapCCWith
, llvmPackages_latest
}:


let

  # We need to replace the lld linker from bintools with our linker just built,
  # otherwise we run into incompatibility issues when mixing compiler and linker
  # versions.
  bintools-unwrapped = llvmPackages_latest.tools.bintools-unwrapped.override {
    lld = clangOmpss2Unwrapped;
  };
  bintools = llvmPackages_latest.tools.bintools.override {
    bintools = bintools-unwrapped;
  };
  targetConfig = stdenv.targetPlatform.config;
  inherit gcc;
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

    wrap clang++  $wrapper $ccPath/clang++
  '';
}
