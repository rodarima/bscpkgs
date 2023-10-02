{
  stdenv
, autoreconfHook
, boost
, libxml2
, xml2
, wxGTK30
, autoconf
, automake
, pkg-config
}:

let
  wx = wxGTK30;
in
stdenv.mkDerivation rec {
  pname = "paraver-kernel";
  version = "${src.shortRev}";

  src = builtins.fetchGit {
    url = "https://github.com/bsc-performance-tools/paraver-kernel.git";
    rev = "3f89ec68da8e53ee227c57a2024bf789fa68ba98"; # master (missing tag)
    ref = "master";
  };

  patches = [
    # https://github.com/bsc-performance-tools/paraver-kernel/pull/11
    ./dont-expand-colors.patch
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
  ];
}
