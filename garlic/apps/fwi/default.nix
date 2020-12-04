{
  stdenv
, nanos6
, mpi
, tampi
, mcxx
, icc
}:

stdenv.mkDerivation rec {
  name = "fwi";
  variant = "oss+task";

  src = builtins.fetchGit {
    url = "https://gitlab.com/srodrb/BSC-FWI.git";
    ref = "${variant}";
  };

  enableParallelBuilding = true;

  buildInputs = [
    nanos6
    mpi
    icc
    tampi
    mcxx
  ];

  # FIXME: This is an ugly hack.
  # When using _GNU_SOURCE or any other definition used in features.h, we need
  # to define them before mcc includes nanos6.h from the command line. So the
  # only chance is by setting it at the command line with -D. Using the DEFINES
  # below, reaches the command line of the preprocessing stage with gcc.
  preConfigure = ''
    export DEFINES=-D_GNU_SOURCE
    export NANOS6_CONFIG_OVERRIDE=version.debug=true
  '';
  
  # We compile the ModelGenerator using gcc *only*, as otherwise it will
  # be compiled with nanos6, which requires access to /sys to determine
  # hardware capabilities. So it will fail in the nix-build environment,
  # as there is no /sys mounted.
  preBuild = ''
    make COMPILER=GNU ModelGenerator
  '';

  makeFlags = [
    "NZF=108"
    "NXF=108"
    "NYF=208"
    "PRECISION=float"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp fwi $out/bin
    cp ModelGenerator $out/bin
  '';
}
