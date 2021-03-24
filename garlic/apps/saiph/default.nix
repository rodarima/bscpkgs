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
, enableManualDist ? false
, nbgx ? null
, nbgy ? null
, nbgz ? null
, nblx ? null
, nbly ? null
, nblz ? null
, nsteps ? null
, numComm ? null
, enableVectFlags ? false
, enableDebugFlags ? false
, enableAsanFlags ? false
, cachelineBytes ? 64
, l3sizeKBytes ? 33792
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
  ];

  # Required for nanos6
  hardeningDisable = [ "bindnow" ];
  
  preBuild = ''
    cd saiphv2/cpp/src 
    export VTK_VERSION=8.2
    export VTK_HOME=${vtk}
    make clean
  '';

  #NIX_CFLAGS_COMPILE = "-O1 -g";
  #NIX_DEBUG = 5;

  makeFlags = [
    "-f" "Makefile.${cc.CC}"
    "apps"
    "APP=Heat3D_vect"
    "ROW_ALIGNMENT=${toString cachelineBytes}"
    "L3_SIZE_K=${toString l3sizeKBytes}"
  ] ++ optional (enableManualDist) "DIST_SET=1"
    ++ optional (enableManualDist) "NBG_X=${toString nbgx}"
    ++ optional (enableManualDist) "NBG_Y=${toString nbgy}"
    ++ optional (enableManualDist) "NBG_Z=${toString nbgz}"
    ++ optional (nblx != null) "NBL_X=${toString nblx}"
    ++ optional (nbly != null) "NBL_Y=${toString nbly}"
    ++ optional (nblz != null) "NBL_Z=${toString nblz}"
    ++ optional (nsteps != null) "NSTEPS=${toString nsteps}"
    ++ optional (numComm != null) "NUM_COMM=${toString numComm}"
    ++ optional (enableVectFlags) "VECT_CHECKS=1"
    ++ optional (enableDebugFlags) "DEBUG_CHECKS=1"
    ++ optional (enableAsanFlags) "SANITIZE_CHECKS=1"
    ;
    
  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/bin
    cp obj/libsaiphv2.so $out/lib/
    cp bin/Heat3D_vect $out/bin/
  '';
}
