{
  stdenv
, nanos6
, mpi
, tampi
, cc 
, vtk
, boost
, devMode ? false
, gitBranch ? "master"
, numComm ? null
, vectFlags ? null
#, breakpointHook
}:

stdenv.mkDerivation rec {
  name = "saiph";

  src = (if (devMode == true) then ~/repos/saiph
         else
	 builtins.fetchGit {
           url = "ssh://git@bscpm02.bsc.es/DSLs/saiph.git";
           ref = "${gitBranch}";
         });

  programPath = "/bin/ExHeat3D";

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
  ''
  + (if (devMode == true) then "make clean" else "")
  ;

  makeFlags = [
    "-f" "Makefile.${cc.cc.CC}"
    "apps"
    "APP=ExHeat3D"
    ( if (numComm != null) then "NUM_COMM=${toString numComm}" else "" )
    ( if (vectFlags != null) then "VECT_FLAGS=${toString vectFlags}" else "" )
  ];

  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/bin
    cp obj/libsaiphv2.so $out/lib/
    cp bin/ExHeat3D $out/bin/
  '';
}
