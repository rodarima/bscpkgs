{
  stdenv
, cmake
, ifort
, impi
, pkgconfig
, icc
}:

stdenv.mkDerivation rec {
  pname = "alya";
  version = "${src.shortRev}";
  src = builtins.fetchGit {
    url = "ssh://git@alya.gitlab.bsc.es/alya/alya.git";
    ref = "master";
    rev = "d7bd220b4ecf70f745c9c3667b4e830a6b3e76dc";
  };
  buildInputs = [ cmake ifort impi pkgconfig icc ];
  cmakeFlags = [
    #"--debug-trycompile"
    #"--debug-find"
    "-DUSEMPIF08=ON"
    "-DCMAKE_C_COMPILER=icc"
    "-DCMAKE_CXX_COMPILER=icpc"
    "-DCMAKE_Fortran_COMPILER=ifort"
    "-DMPI_HOME=${impi}"
    #"-DMPI_C_COMPILER=mpicc"
    #"-DMPI_CXX_COMPILER=mpicxx"
    #"-DWITH_ALL_MODULES=OFF" "-DWITH_MODULE_NASTIN=ON"
    "-DWITH_NDIMEPAR=ON"
    #"-DWITH_CTEST=OFF"
    "-DINTEGER_SIZE=8"
  ];
  #I_MPI_ROOT = impi;
  #VERBOSE = 1;
  #NIX_DEBUG = 5;
  enableParallelBuilding = true;
  dontStrip = true;
  hardeningDisable = [ "all" ];
}
