{
  stdenv
, gcc
, iccUnwrapped
, wrapCCWith
}:

let
  targetConfig = stdenv.targetPlatform.config;
  inherit gcc;
in wrapCCWith rec {
  cc = iccUnwrapped;
  extraBuildCommands = ''
    echo "-B${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-cflags
    echo "-isystem ${iccUnwrapped}/include" >> $out/nix-support/cc-cflags
    echo "-isystem ${iccUnwrapped}/include/icc" >> $out/nix-support/cc-cflags
    echo "-L${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-ldflags
    echo "-L${gcc.cc.lib}/lib" >> $out/nix-support/cc-ldflags

    # Create the wrappers for icc and icpc
    wrap icx  $wrapper $ccPath/icx
    wrap icx  $wrapper $ccPath/icpx
    wrap icx  $wrapper $ccPath/clang
    wrap icx  $wrapper $ccPath/clang++
  '';
}
