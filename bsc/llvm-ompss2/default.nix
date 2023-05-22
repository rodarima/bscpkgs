{
  stdenv
, gcc
, rt
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

  homevar = if rt.pname == "nanos6" then "NANOS6_HOME" else "NODES_HOME";
  rtname = if rt.pname == "nanos6" then "libnanos6" else "libnodes";

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

    # Setup NANOS6_HOME or NODES_HOME, based on the runtime.
    echo "export ${homevar}=${rt}" >> $out/nix-support/setup-hook
    echo "export OMPSS2_RUNTIME=${rtname}" >> $out/nix-support/setup-hook

    wrap clang++  $wrapper $ccPath/clang++
  '';
}
