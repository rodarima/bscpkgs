{
  stdenv
, cc
, mpi ? null
, cflags ? null
, gitBranch
, gitURL ? "ssh://git@bscpm02.bsc.es/garlic/apps/nbody.git"
, blocksize ? 2048
}:

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "nbody";

  src = builtins.fetchGit {
    url = "${gitURL}";
    ref = "${gitBranch}";
  };

  buildInputs = [
    cc
  ]
  ++ optional (mpi != null) [ mpi ];

  preBuild = (if cflags != null then ''
    makeFlagsArray+=(CFLAGS="${cflags}")
  '' else "");

  makeFlags = [
    "CC=${cc.cc.CC}"
    "BS=${toString blocksize}"
  ];

  dontPatchShebangs = true;

  installPhase = ''
    mkdir -p $out/bin
    cp nbody* $out/bin/${name}
    ln -s $out/bin/${name} $out/bin/run
  '';

}
