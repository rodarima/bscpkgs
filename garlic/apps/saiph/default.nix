{
  stdenv
, nanos6
, mpi
, tampi
, cc 
, vtk
, boost
, gitBranch ? "master"
, numComm ? null
, nbx ? null
, nby ? null
, nbz ? null
, vectFlags ? null
#, breakpointHook
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "saiph";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/DSLs/saiph.git";
    ref = "${gitBranch}";
  };

  programPath = "/bin/Heat3D_vect";

  enableParallelBuilding = true;
  dontStrip = true;
  enableDebugging = true;

  buildInputs = [
    nanos6
    mpi
    tampi
    cc
    vtk
    boost
#    breakpointHook
  ];

  # Required for nanos6
  hardeningDisable = [ "bindnow" ];
  
  preBuild = ''
    cd saiphv2/cpp/src 
    export VTK_VERSION=8.2
    export VTK_HOME=${vtk}
    make clean
  '';

  makeFlags = [
    "-f" "Makefile.${cc.cc.CC}"
    "apps"
    "APP=Heat3D_vect"
  ] ++ optional (nbx != null) "NB_X=${toString nbx}"
    ++ optional (nby != null) "NB_Y=${toString nby}"
    ++ optional (nbz != null) "NB_Z=${toString nbz}"
    ++ optional (numComm != null) "NUM_COMM=${toString numComm}"
    ++ optional (vectFlags != null) "VECT_FLAGS=${toString vectFlags}"
    ;
    
  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/bin
    cp obj/libsaiphv2.so $out/lib/
    cp bin/Heat3D_vect $out/bin/
  '';
}
