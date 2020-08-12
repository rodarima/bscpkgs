{
  stdenv
, cc
, cflags ? null
, gitBranch
, blocksize ? 2048
}:

stdenv.mkDerivation rec {
  name = "nbody";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/rarias/nbody.git";
    ref = "${gitBranch}";
  };

  buildInputs = [
    cc
  ];

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
