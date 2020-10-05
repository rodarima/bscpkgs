{
  stdenv
, glibc
, targetCluster
, nixPrefix
}:

stdenv.mkDerivation rec {
  name = "nixtools-${targetCluster}";
  #version = "${src.shortRev}";
  src = ~/nixtools;
  buildInputs = [ glibc.static ];
  makeFlags = [ "DESTDIR=$(out)" ];
  preBuild = "env";
  dontPatchShebangs = true;
  inherit nixPrefix targetCluster;
  postPatch = ''
    substituteAllInPlace scripts/cobi/runexp
    sed -i s:@nixtools@:$out:g scripts/cobi/runexp
  '';
  #src = builtins.fetchGit {
  #  url = "ssh://git@bscpm02.bsc.es/rarias/nixtools";
  #  ref = "master";
  #};
}
