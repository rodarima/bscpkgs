{
  lib,
  stdenv,
  libtirpc,
  fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "lmbench";
  version = "941a0dcc";

  # We use the intel repo as they have fixed some problems
  src = fetchFromGitHub {
    owner = "intel";
    repo = pname;
    rev = "941a0dcc0e7bdd9bb0dee05d7f620e77da8c43af";
    sha256 = "sha256-SzwplRBO3V0R3m3p15n71ivYBMGoLsajFK2TapYxdqk=";
  };

  postUnpack = ''
    export sourceRoot="$sourceRoot/src"
  '';

  postPatch = ''
    sed -i "s@/bin/rm@rm@g" $(find . -name Makefile)
  '';

  buildInputs = [ libtirpc ];
  patches = [ ./fix-install.patch ];

  hardeningDisable = [ "all" ];

  enableParallelBuilding = false;

  preBuild = ''
    makeFlagsArray+=(
      BASE=$out
      CPPFLAGS=-I${libtirpc.dev}/include/tirpc
      LDFLAGS=-ltirpc
    )
  '';

  meta = {
    description = "lmbench";
    homepage = "http://www.bitmover.com/lmbench/";
    maintainers = [ ];
    platforms = lib.platforms.all;
  };
}
