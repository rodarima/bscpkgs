{
  stdenv
, mpi ? null
, tampi ? null
, mcxx ? null
, cc
, gitBranch ? "garlic/tampi+send+oss+task"
, fwiInput
}:

with stdenv.lib;

assert !(tampi != null && mcxx == null);

stdenv.mkDerivation rec {
  inherit gitBranch;
  name = "fwi";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/garlic/apps/fwi.git";
    ref = "${gitBranch}";
  };

  enableParallelBuilding = false;

  buildInputs = [
    cc
  ]
  ++ optional (mpi   != null) mpi
  ++ optional (tampi != null) tampi
  ++ optional (mcxx  != null) mcxx;

  # FIXME: Correct this on the Makefile so we can just type "make fwi"
  # FIXME: Allow multiple MPI implementations
  postPatch = ''
    sed -i 's/= OPENMPI$/= INTEL/g' Makefile
    sed -i 's/USE_O_DIRECT ?= NO/USE_O_DIRECT ?= YES/g' Makefile || true
  '';

  # FIXME: This is an ugly hack.
  # When using _GNU_SOURCE or any other definition used in features.h, we need
  # to define them before mcc includes nanos6.h from the command line. So the
  # only chance is by setting it at the command line with -D. Using the DEFINES
  # below, reaches the command line of the preprocessing stage with gcc.
  preConfigure = ''
    export DEFINES=-D_GNU_SOURCE

    make depend

    cp ${fwiInput}/generated_model_params.h src/
  '';
  
  # We compile the ModelGenerator using gcc *only*, as otherwise it will
  # be compiled with nanos6, which requires access to /sys to determine
  # hardware capabilities. So it will fail in the nix-build environment,
  # as there is no /sys mounted.
  makeFlags = [
    #"COMPILER=GNU"
    #"CC=${cc.cc.CC}"
    "fwi"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp fwi $out/bin
  '';

  programPath = "/bin/fwi";
}
