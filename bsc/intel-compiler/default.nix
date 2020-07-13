{
  stdenv
, gcc
, nanos6
, icc-unwrapped
, wrapCCWith
, libstdcxxHook
, intel-license
}:

let
  targetConfig = stdenv.targetPlatform.config;
  inherit gcc;
in wrapCCWith rec {
  cc = icc-unwrapped;
  extraBuildCommands = ''
    echo "-B${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-cflags
    echo "-isystem ${icc-unwrapped}/include" >> $out/nix-support/cc-cflags
    echo "-isystem ${icc-unwrapped}/include/intel64" >> $out/nix-support/cc-cflags
    echo "-L${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-ldflags
    echo "-L${gcc.cc.lib}/lib" >> $out/nix-support/cc-ldflags

    cat "${icc-unwrapped}/nix-support/propagated-build-inputs" >> \
      $out/nix-support/propagated-build-inputs

    echo "export INTEL_LICENSE_FILE=${intel-license}" \
      >> $out/nix-support/setup-hook

    # Create the wrappers for icc and icpc
    wrap icc  $wrapper $ccPath/icc
    wrap icpc $wrapper $ccPath/icpc
    wrap ifort $wrapper $ccPath/ifort
  '';
}
