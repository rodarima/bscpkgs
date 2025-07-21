{
  stdenv
, fetchFromGitHub
, autoreconfHook
, boost
, libxml2
, xml2
, wxGTK32
, autoconf
, automake
, pkg-config
, zlib
}:

let
  wx = wxGTK32;
in
stdenv.mkDerivation rec {
  pname = "paraver-kernel";
  version = "4.12.0";

  src = fetchFromGitHub {
    owner = "bsc-performance-tools";
    repo = "paraver-kernel";
    rev = "v${version}";
    sha256 = "sha256-Xs7g8ITZhPt00v7o2WlTddbou8C8Rc9kBMFpl2WsCS4=";
  };

  patches = [
    # https://github.com/bsc-performance-tools/paraver-kernel/pull/11
    # TODO: add this back if it's still relevant
    # ./dont-expand-colors.patch
    ./fix-libxml2-deprecation.patch
  ];

  hardeningDisable = [ "all" ];
  enableParallelBuilding = true;

  dontStrip = true;

  preConfigure = ''
    export CFLAGS="-O3 -DPARALLEL_ENABLED"
    export CXXFLAGS="-O3 -DPARALLEL_ENABLED"
  '';

  configureFlags = [
    "--with-boost=${boost}"
    "--enable-openmp"
  ];

  buildInputs = [
    autoreconfHook
    boost
    libxml2.dev
    xml2
    autoconf
    automake
    pkg-config
    zlib
  ];
}
