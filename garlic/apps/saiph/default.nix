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
, manualDist ? 0
, nbgx ? null
, nbgy ? null
, nbgz ? null
, nblx ? null
, nbly ? null
, nblz ? null
, nsteps ? null
, vectFlags ? null
, debugFlags ? null
, asanFlags ? null
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
  ] ++ optional (manualDist != 0) "DIST_SET=${toString manualDist}"
    ++ optional (manualDist != 0) "NBG_X=${toString nbgx}"
    ++ optional (manualDist != 0) "NBG_Y=${toString nbgy}"
    ++ optional (manualDist != 0) "NBG_Z=${toString nbgz}"
    ++ optional (nblx != null) "NBL_X=${toString nblx}"
    ++ optional (nbly != null) "NBL_Y=${toString nbly}"
    ++ optional (nblz != null) "NBL_Z=${toString nblz}"
    ++ optional (nsteps != null) "NSTEPS=${toString nsteps}"
    ++ optional (numComm != null) "NUM_COMM=${toString numComm}"
    ++ optional (vectFlags != null) "VECT_CHECKS=${toString vectFlags}"
    ++ optional (debugFlags != null) "DEBUG_CHECKS=${toString debugFlags}"
    ++ optional (asanFlags != null) "SANITIZE_CHECKS=${toString asanFlags}"
    ;
    
  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/bin
    cp obj/libsaiphv2.so $out/lib/
    cp bin/Heat3D_vect $out/bin/
  '';
}
