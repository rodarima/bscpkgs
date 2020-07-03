{
  stdenv
, nanos6
, mpi
, tampi
, mcxx
, vtk
, boost
}:

stdenv.mkDerivation rec {
  name = "saiph";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/DSLs/saiph.git";
    ref = "VectorisationSupport";
  };

  #src = /tmp/saiph;

  enableParallelBuilding = true;
  dontStrip = true;
  enableDebugging = true;

  buildInputs = [
    nanos6
    mpi
    tampi
    mcxx
    vtk
    boost
  ];

  preBuild = ''
    cd saiphv2/cpp/src

    sed -i s/skylake-avx512/core-avx2/g Makefile*
    export VTK_VERSION=8.2
    export VTK_HOME=${vtk}
    export SAIPH_HOME=.
    export NIX_CFLAGS_COMPILE+=" -fsanitize=address"
  '';

  makeFlags = [
    "-f" "Makefile.clang"
    "apps"
    "APP=ExHeat"
  ];

  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/bin
    cp obj/libsaiphv2.so $out/lib/
    cp bin/ExHeat $out/bin/
  '';
}
