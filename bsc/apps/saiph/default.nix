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
  name = "nbody";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/DSLs/saiph.git";
    #rev = "a8372abf9fc7cbc2db0778de80512ad4af244c29";
    ref = "VectorisationSupport";
  };

  #dontStrip = true;

#  preBuild = ''
#    cd saiphv2/cpp/src
#  '';

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
    make -f Makefile.clang apps=ExHeat
  '';

  installPhase = ''
    mkdir -p $out/bin
    #cp nbody_* $out/bin/
  '';
}
