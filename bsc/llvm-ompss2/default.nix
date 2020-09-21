{
  stdenv
, gcc
, nanos6
, clangOmpss2Unwrapped
, wrapCCWith
}:


let
  targetConfig = stdenv.targetPlatform.config;
  inherit gcc nanos6;
in wrapCCWith rec {
  cc = clangOmpss2Unwrapped;
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
  '';
}
