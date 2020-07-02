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
    #rev = "a8372abf9fc7cbc2db0778de80512ad4af244c29";
    ref = "VectorisationSupport";
  };


  enableParallelBuilding = true;
  dontStrip = true;

  buildInputs = [
    nanos6
    mpi
    tampi
    mcxx
    vtk
    boost
  ];

  buildPhase = ''
    pwd
    cd saiphv2/cpp/src
    export VTK_VERSION=8.2
    export VTK_HOME=${vtk}
    export SAIPH_HOME=.
    make -f Makefile.clang
    make -f Makefile.clang apps APP=ExHeat -j
  '';

  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/bin
    cp obj/libsaiphv2.so $out/lib/
    cp bin/ExHeat $out/bin/
  '';
}
