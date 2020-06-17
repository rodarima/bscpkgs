{
  stdenv
, gcc
, nanos6
, clang-ompss2-unwrapped
, wrapCCWith
, libstdcxxHook
}:


let
  targetConfig = stdenv.targetPlatform.config;
  inherit gcc nanos6;
in wrapCCWith rec {
  cc = clang-ompss2-unwrapped;
  extraPackages = [ libstdcxxHook ];
  extraBuildCommands = ''
    echo "-target ${targetConfig}" >> $out/nix-support/cc-cflags
    echo "-B${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-cflags
    echo "-L${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-ldflags
    echo "-L${gcc.cc.lib}/lib" >> $out/nix-support/cc-ldflags
    echo "--gcc-toolchain=${gcc}" >> $out/nix-support/cc-cflags

    echo "# Hack to include NANOS6_HOME" >> $out/nix-support/setup-hook
    echo "export NANOS6_HOME=${nanos6}" >> $out/nix-support/setup-hook
  '';
}
