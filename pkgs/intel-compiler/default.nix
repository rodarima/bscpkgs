{
  stdenv
, gcc
, iccUnwrapped
, wrapCCWith
, intelLicense
}:

let
  targetConfig = stdenv.targetPlatform.config;
  inherit gcc;
in wrapCCWith rec {
  cc = iccUnwrapped;
  extraBuildCommands = ''
    echo "-B${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-cflags
    echo "-isystem ${iccUnwrapped}/include" >> $out/nix-support/cc-cflags
    echo "-isystem ${iccUnwrapped}/include/intel64" >> $out/nix-support/cc-cflags
    echo "-L${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-ldflags
    echo "-L${gcc.cc.lib}/lib" >> $out/nix-support/cc-ldflags

    cat "${iccUnwrapped}/nix-support/propagated-build-inputs" >> \
      $out/nix-support/propagated-build-inputs

    echo "export INTEL_LICENSE_FILE=${intelLicense}" \
      >> $out/nix-support/setup-hook

    # Create the wrappers for icc and icpc
    if [ -e $ccPath/icc ]; then
      wrap icc  $wrapper $ccPath/icc
    fi

    if [ -e $ccPath/icpc ]; then
      wrap icpc $wrapper $ccPath/icpc
    fi

    if [ -e $ccPath/ifort ]; then
      wrap ifort $wrapper $ccPath/ifort
    fi
  '';
}
