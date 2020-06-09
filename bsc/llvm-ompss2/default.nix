{
  stdenv
, fetchgit
, cmake
, lld
}:

stdenv.mkDerivation rec {
  version = "10.0.0";
  name = "llvm-ompss2-${version}";
  enableParallelBuilding = true;
  buildInputs = [ cmake lld ];
  preConfigure = ''
      ls
      mkdir llvm-build
      cd llvm-build
      ../utils/OmpSs/setup-cmake.sh
  '';
  src = "./llvm-mono/";
  #dontUnpack = true;
}
