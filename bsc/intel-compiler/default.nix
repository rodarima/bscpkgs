{
  stdenv
, gcc
, nanos6
, icc-unwrapped
, wrapCCWith
, libstdcxxHook
, icc-license
}:

let
  targetConfig = stdenv.targetPlatform.config;
  inherit gcc;
in wrapCCWith rec {
  cc = icc-unwrapped;
  extraPackages = [ libstdcxxHook ];
  extraBuildCommands = ''
    echo "-B${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-cflags
    echo "-L${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-ldflags
    echo "-L${gcc.cc.lib}/lib" >> $out/nix-support/cc-ldflags

    echo "export INTEL_LICENSE_FILE=${icc-license}" \
      >> $out/nix-support/setup-hook

    # Create the wrappers for icc and icpc
    wrap icc  $wrapper $ccPath/icc
    wrap icpc $wrapper $ccPath/icpc
  '';
}
