{ lib
, llvmPackages_latest
, monorepoSrc
, runCommand
, cmake
, ninja
, llvm
, perl
, pkg-config
, version
, nosv
, enableDebug ? false
}:

let
  stdenv = llvmPackages_latest.stdenv;
in
stdenv.mkDerivation rec {
  pname = "openmp";
  inherit version;

  src = runCommand "${pname}-src" {} ''
    mkdir -p "$out"
    cp -r ${monorepoSrc}/cmake "$out"
    cp -r ${monorepoSrc}/${pname} "$out"
  '';

  sourceRoot = "${src.name}/${pname}";

  nativeBuildInputs = [
    cmake
    ninja
    perl
    pkg-config
    nosv
  ];

  doCheck = false;

  hardeningDisable = [ "all" ];

  cmakeBuildType = if enableDebug then "Debug" else "Release";

  dontStrip = enableDebug;

  cmakeFlags = [
    "-DLIBOMP_OMPD_SUPPORT=OFF"
    "-DOPENMP_ENABLE_LIBOMPTARGET=OFF"
  ];

  # Remove support for GNU and Intel Openmp
  postInstall = ''
    rm -f $out/lib/libgomp*
    rm -f $out/lib/libiomp*
  '';
}

