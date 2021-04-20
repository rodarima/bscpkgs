{
  stdenv
, nz ? 200
, nx ? 200
, ny ? 500
, gitBranch ? "garlic/seq"
, gitCommit ? null
, garlicTools
}:

with stdenv.lib;
with builtins;

let
  gitSource = garlicTools.fetchGarlicApp {
    appName = "fwi";
    inherit gitCommit gitBranch;
    gitTable = import ./git-table.nix;
  };
in
  stdenv.mkDerivation rec {
    name = "fwi-params";

    inherit (gitSource) src gitBranch gitCommit;

    enableParallelBuilding = false;

    # Set the input size with the weird order (nz,nx,ny).
    postPatch = ''
      sed -i 1c${toString nz} SetupParams/fwi_params.txt
      sed -i 2c${toString nx} SetupParams/fwi_params.txt
      sed -i 3c${toString ny} SetupParams/fwi_params.txt
    '';

    # FIXME: This is an ugly hack.
    # When using _GNU_SOURCE or any other definition used in features.h, we need
    # to define them before mcc includes nanos6.h from the command line. So the
    # only chance is by setting it at the command line with -D. Using the DEFINES
    # below, reaches the command line of the preprocessing stage with gcc.
    preConfigure = ''
      export DEFINES=-D_GNU_SOURCE
    '';
    
    # We compile the ModelGenerator using gcc *only*, as otherwise it will
    # be compiled with nanos6, which requires access to /sys to determine
    # hardware capabilities. So it will fail in the nix-build environment,
    # as there is no /sys mounted.
    # Also, we need to compile it with the builder platform as target, as is going
    # to be executed during the build to generate the src/generated_model_params.h
    # header.
    makeFlags = [ "COMPILER=GNU" "params" ];

    installPhase = ''
      mkdir -p $out/
      cp src/generated_model_params.h $out/
      cp SetupParams/fwi_params.txt $out/
      cp SetupParams/fwi_frequencies.txt $out/

      mkdir -p $out/bin
      cp ModelGenerator $out/bin/
    '';
  }
