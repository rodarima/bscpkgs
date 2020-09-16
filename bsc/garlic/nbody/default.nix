{
  stdenv
, cc
, tampi ? null
, mpi ? null
, cflags ? null
, gitBranch
, gitURL ? "ssh://git@bscpm02.bsc.es/garlic/apps/nbody.git"
, blocksize ? 2048
}:

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "nbody";

  src = /home/Computational/rarias/bscpkgs/manual/nbody;

  #src = builtins.fetchGit {
  #  url = "${gitURL}";
  #  ref = "${gitBranch}";
  #};
  programPath = "/bin/nbody";

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
    echo ${tampi}
    mkdir -p $out/bin
    cp nbody* $out/bin/${name}
  '';

}
