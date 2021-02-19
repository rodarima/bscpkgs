{
  stdenv
, nanos6
, mpi
, tampi
, cc 
, vtk
, boost
, gitBranch ? "master"
, gitCommit ? null
, numComm ? null
, nbx ? null
, nby ? null
, nbz ? null
, vectFlags ? null
, cachelineBytes ? 64
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "saiph";

  inherit gitBranch gitCommit;
  src = builtins.fetchGit ({
    url = "ssh://git@bscpm03.bsc.es/DSLs/saiph.git";
    ref = "${gitBranch}";
  } // (if (gitCommit != null) then {
    rev = gitCommit;
  } else {}));

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
    "-f" "Makefile.${cc.CC}"
    "apps"
    "APP=Heat3D_vect"
    "ROW_ALIGNMENT=${toString cachelineBytes}"
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
