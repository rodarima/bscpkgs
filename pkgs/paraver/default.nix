{
  stdenv
, autoreconfHook
, boost
, libxml2
, xml2
, wxGTK32
, autoconf
, automake
, paraverKernel
, openssl
, glibcLocales
}:

let
  wx = wxGTK32;
in
stdenv.mkDerivation rec {
  pname = "wxparaver";
  version = "4.10.6";

  src = builtins.fetchGit {
    url = "https://github.com/bsc-performance-tools/wxparaver.git";
    rev = "fe55c724ab59a5b0e60718919297bdf95582badb"; # v4.10.6 (missing tag)
    ref = "master";
  };

  hardeningDisable = [ "all" ];

  # Fix the PARAVER_HOME variable
  postPatch = ''
    sed -i 's@^PARAVER_HOME=.*$@PARAVER_HOME='$out'@g' docs/wxparaver
    sed -i '1aexport LOCALE_ARCHIVE="${glibcLocales}/lib/locale/locale-archive"' docs/wxparaver
  '';

  dontStrip = true;
  enableParallelBuilding = true;

  preConfigure = ''
    export CFLAGS="-O3"
    export CXXFLAGS="-O3"
  '';

  configureFlags = [
    "--with-boost=${boost}"
    "--with-wx-config=${wx}/bin/wx-config"
    "--with-paraver=${paraverKernel}"
    "--with-openssl=${openssl.dev}"
  ];

  buildInputs = [
    autoreconfHook
    boost
    libxml2.dev
    xml2
    wx
    autoconf
    automake
    paraverKernel
    openssl.dev
    paraverKernel
  ];

  postInstall = ''
    mkdir -p $out/include
    mkdir -p $out/lib/paraver-kernel
    mkdir -p $out/share/filters-config
    cp -p ${paraverKernel}/bin/* $out/bin
    # cp -p ${paraverKernel}/include/* $out/include
    cp -a ${paraverKernel}/lib/paraver-kernel $out/lib/paraver-kernel
    cp -p ${paraverKernel}/share/filters-config/* $out/share/filters-config
  '';
}
