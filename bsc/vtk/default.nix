{
  stdenv
, fetchurl
, cmake
, libGLU
, libGL
, libX11
, xorgproto
, libXt
, libtiff
, qtLib ? null
, enablePython ? false, python ? null
, mpi ? null
}:

with stdenv.lib;

let
  os = stdenv.lib.optionalString;
  majorVersion = "8.2";
  minorVersion = "0";
  version = "${majorVersion}.${minorVersion}";
in

stdenv.mkDerivation rec {
  name = "vtk-${os (qtLib != null) "qvtk-"}${version}";
  src = fetchurl {
    url = "${meta.homepage}files/release/${majorVersion}/VTK-${version}.tar.gz";
    sha256 = "1fspgp8k0myr6p2a6wkc21ldcswb4bvmb484m12mxgk1a9vxrhrl";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ libtiff ]
    ++ optionals (qtLib != null) (with qtLib; [ qtbase qtx11extras qttools ])
    ++ optional (qtLib != null) (with qtLib; [ qtbase qtx11extras qttools ])
    ++ optionals stdenv.isLinux [ libGLU libGL libX11 xorgproto libXt ]
    ++ optional enablePython [ python ]
    ++ optional (mpi != null) [ mpi ];

  preBuild = ''
    export LD_LIBRARY_PATH="$(pwd)/lib";
  '';

  # Shared libraries don't work, because of rpath troubles with the current
  # nixpkgs cmake approach. It wants to call a binary at build time, just
  # built and requiring one of the shared objects.
  # At least, we use -fPIC for other packages to be able to use this in shared
  # objects.
  cmakeFlags = [
    "-DCMAKE_C_FLAGS=-fPIC"
    "-DCMAKE_CXX_FLAGS=-fPIC"
    "-DVTK_USE_SYSTEM_TIFF=1"
    "-DVTK_Group_MPI=ON"
    "-DBUILD_SHARED_LIBS=ON"
    "-DOPENGL_INCLUDE_DIR=${libGL}/include"
  ]
  ++ optional (mpi != null) [
    "-DVTK_Group_MPI=ON" ]
  ++ optional (qtLib != null) [
    "-DVTK_Group_Qt:BOOL=ON" ]
  ++ optional stdenv.isDarwin [
    "-DOPENGL_INCLUDE_DIR=${OpenGL}/Library/Frameworks" ]
  ++ optional enablePython [
    "-DVTK_WRAP_PYTHON:BOOL=ON" ];

  enableParallelBuilding = true;

  meta = {
    description = "Open source libraries for 3D computer graphics, image processing and visualization";
    homepage = "https://www.vtk.org/";
    license = stdenv.lib.licenses.bsd3;
    maintainers = with stdenv.lib.maintainers; [ knedlsepp ];
    platforms = with stdenv.lib.platforms; unix;
  };
}
