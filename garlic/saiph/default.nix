{
  stdenv
, nanos6
, mpi
, tampi
, mcxx
, vtk
, boost
, gitBranch ? "master"
, numComm ? null
}:

stdenv.mkDerivation rec {
  name = "saiph";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/DSLs/saiph.git";
    ref = "${gitBranch}";
  };

  #src = /tmp/saiph;
  
  programPath = "/bin/ExHeat3D";

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

  # Required for nanos6
  hardeningDisable = [ "bindnow" ];
  
#  Enable debug
#  postPatch = ''
#    sed -i 's/^SANITIZE_FLAGS=/SANITIZE_FLAGS=$(DEBUG_FLAGS)/g' \
#      saiphv2/cpp/src/Makefile.clang
#  '';

  preBuild = ''
    cd saiphv2/cpp/src

    export VTK_VERSION=8.2
    export VTK_HOME=${vtk}
    export BOOST_HOME=${boost}
    export SAIPH_HOME=.
  '';

  makeFlags = [
    "-f" "Makefile.clang"
    "apps"
    "APP=ExHeat3D"
    ( if (numComm != null) then "NUM_COMM=${toString numComm}" else "" )
  ];

  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/bin
    cp obj/libsaiphv2.so $out/lib/
    cp bin/ExHeat3D $out/bin/
  '';
}
