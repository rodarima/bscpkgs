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
, cachelineBytes ? null
, L3SizeKB ? null
# Problem size:
, sizex ? 3
, sizey ? 4
, sizez ? 4
, garlicTools
}:

assert enableManualDist -> (nbgx != null);
assert enableManualDist -> (nbgy != null);
assert enableManualDist -> (nbgz != null);

with stdenv.lib;
with stdenv.lib.versions;

let
  gitSource = garlicTools.fetchGarlicApp {
    appName = "saiph";
    inherit gitCommit gitBranch;
    gitTable = import ./git-table.nix;
  };
in
  stdenv.mkDerivation rec {
    name = "saiph";

    inherit (gitSource) src gitBranch gitCommit;

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
    
    preBuild = ''
      cd saiphv2/cpp/src 
      export VTK_VERSION=${majorMinor (getVersion vtk.name)}
      export VTK_HOME=${vtk}
      make clean

      sed -i '/SIZEX =/s/3/${toString sizex}/g' testApp/Heat3D_vect.cpp
      sed -i '/SIZEY =/s/4/${toString sizey}/g' testApp/Heat3D_vect.cpp
      sed -i '/SIZEZ =/s/4/${toString sizez}/g' testApp/Heat3D_vect.cpp
    '';

    makeFlags = [
      "-f" "Makefile.${cc.CC}"
      "apps"
      "APP=Heat3D_vect"
    ] ++ optional (cachelineBytes != null) "ROW_ALIGNMENT=${toString cachelineBytes}"
      ++ optional (L3SizeKB != null)  "L3_SIZE_K=${toString L3SizeKB}"
      ++ optional (enableManualDist)  "DIST_SET=1"
      ++ optional (enableManualDist)  "NBG_X=${toString nbgx}"
      ++ optional (enableManualDist)  "NBG_Y=${toString nbgy}"
      ++ optional (enableManualDist)  "NBG_Z=${toString nbgz}"
      ++ optional (nblx != null)      "NBL_X=${toString nblx}"
      ++ optional (nbly != null)      "NBL_Y=${toString nbly}"
      ++ optional (nblz != null)      "NBL_Z=${toString nblz}"
      ++ optional (nsteps != null)    "NSTEPS=${toString nsteps}"
      ++ optional (numComm != null)   "NUM_COMM=${toString numComm}"
      ++ optional (enableVectFlags)   "VECT_CHECKS=1"
      ++ optional (enableDebugFlags)  "DEBUG_CHECKS=1"
      ++ optional (enableAsanFlags)   "SANITIZE_CHECKS=1"
      ;
      
    installPhase = ''
      mkdir -p $out/lib
      mkdir -p $out/bin
      cp obj/libsaiphv2.so $out/lib/
      cp bin/Heat3D_vect $out/bin/
    '';

    hardeningDisable = [ "all" ];
  }
