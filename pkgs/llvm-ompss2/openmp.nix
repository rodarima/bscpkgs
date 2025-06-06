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
, ovni
, python3
, enableNosv ? false
, enableDebug ? false
, enableOvni ? false
}:

assert enableOvni -> enableNosv;

let
  stdenv = llvmPackages_latest.stdenv;
in
stdenv.mkDerivation rec {
  pname = "openmp" + (lib.optionalString enableNosv "-v");
  inherit version;

  src = runCommand "${pname}-src" {} ''
    mkdir -p "$out"
    cp -r ${monorepoSrc}/cmake "$out"
    cp -r ${monorepoSrc}/openmp "$out"
  '';

  sourceRoot = "${src.name}/openmp";

  nativeBuildInputs = [
    cmake
    ninja
    perl
    pkg-config
    python3
  ] ++ lib.optionals enableNosv [
    nosv
  ] ++ lib.optionals enableOvni [
    ovni
  ];

  doCheck = false;

  hardeningDisable = [ "all" ];

  cmakeBuildType = if enableDebug then "Debug" else "Release";

  dontStrip = enableDebug;

  separateDebugInfo = true;

  cmakeFlags = [
    "-DLIBOMP_OMPD_SUPPORT=OFF"
    "-DOPENMP_ENABLE_LIBOMPTARGET=OFF"
  ];

  # Remove support for GNU and Intel Openmp.
  # Also, remove libomp if building with nosv, as there is no support to build
  # only one runtime at a time.
  postInstall = ''
    rm -f $out/lib/libgomp*
    rm -f $out/lib/libiomp*
  '' + lib.optionalString enableNosv ''
    rm -f $out/lib/libomp.*
    rm -f $out/libllvmrt/libomp.*
  '';

  passthru = {
    inherit nosv;
  };
}

