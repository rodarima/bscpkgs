{
  lib,
  stdenv,
  fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "lmbench";
  version = "701c6c35";

  # We use the intel repo as they have fixed some problems
  src = fetchFromGitHub {
    owner = "intel";
    repo = pname;
    rev = "701c6c35b0270d4634fb1dc5272721340322b8ed";
    sha256 = "0sf6zk03knkardsfd6qx7drpm56nhg53n885cylkggk83r38idyr";
  };

  postUnpack = ''
    export sourceRoot="$sourceRoot/src"
  '';

  postPatch = ''
    sed -i "s@/bin/rm@rm@g" $(find . -name Makefile)
  '';

  hardeningDisable = [ "all" ];

  enableParallelBuilding = false;

  preBuild = ''
    makeFlagsArray+=(BASE=$out)
  '';

  meta = {
    description = "lmbench";
    homepage = "http://www.bitmover.com/lmbench/";
    maintainers = [ ];
    platforms = lib.platforms.all;
  };
}
