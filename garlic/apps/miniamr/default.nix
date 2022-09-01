{
  stdenv
, lib
, tampi
, clangOmpss2
, mpi
, nanos6
, mcxx
, variant
}:

with lib;

assert (assertOneOf "variant" variant [ "openmp" "openmp-tasks" "ompss-2" ]);

let
  cc=mcxx;
in
stdenv.mkDerivation rec {
  name = "miniamr";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/ksala/miniamr.git";
    ref = "master";
  };

  postUnpack = ''
    sourceRoot=$sourceRoot/${variant}
  '';

  buildInputs = [ tampi clangOmpss2 mpi nanos6 mcxx ];

  makeFlags = [
    "CC=${cc.CC}"
    "CXX=${cc.CXX}"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin
    cp miniAMR.x $out/bin/
  '';

  programPath = "/bin/miniAMR.x";

  hardeningDisable = [ "all" ];
}
