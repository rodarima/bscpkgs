{
  stdenv
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "fwi-input";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/garlic/apps/fwi.git";
    ref = "garlic/seq";
  };

  enableParallelBuilding = false;

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
  makeFlags = [ "COMPILER=GNU" "params" "input" ];

  installPhase = ''
    mkdir -p $out/
    cp src/generated_model_params.h $out/
    cp -r InputModels $out/
  '';
}
