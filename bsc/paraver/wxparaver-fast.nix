{
  stdenv
, autoreconfHook
, boost
, libxml2
, xml2
, wxpropgrid
, wxGTK28
, autoconf
, automake
, paraverKernelFast
, openssl
}:

let
  wx = wxGTK28;
in
stdenv.mkDerivation rec {
  pname = "paraverFast";
  version = "${src.shortRev}";
  
  src = builtins.fetchGit {
    url = "https://github.com/bsc-performance-tools/wxparaver.git";
    rev = "9fc61decb6d8d9b1cacb50639c3b2c85788b2292";
    ref = "master";
  };

  hardeningDisable = [ "all" ];

  patches = [ ./wxparaver-fast.patch ];

  # Fix the PARAVER_HOME variable
  postPatch = ''
    sed -i 's@^PARAVER_HOME=.*$@PARAVER_HOME='$out'@g' docs/wxparaver
  '';

  dontStrip = true;
  enableParallelBuilding = true;

  preConfigure = ''
    export CFLAGS="-O3"
    export CXXFLAGS="-std=c++17 -O3"
  '';

  configureFlags = [
    "--with-boost=${boost}"
    "--with-wx-config=${wx}/bin/wx-config"
    "--with-wxpropgrid-dir=${wxpropgrid}"
    "--with-paraver=${paraverKernelFast}"
    "--with-openssl=${openssl.dev}"
  ];
  
  buildInputs = [
    autoreconfHook
    boost
    libxml2.dev
    xml2
    wxpropgrid
    wx
    autoconf
    automake
    paraverKernelFast
    openssl.dev
  ];

  postInstall = ''
    mkdir -p $out/include
    mkdir -p $out/lib/paraver-kernel
    mkdir -p $out/share/filters-config
    cp -p ${paraverKernelFast}/bin/* $out/bin
    # cp -p ${paraverKernelFast}/include/* $out/include
    cp -a ${paraverKernelFast}/lib/paraver-kernel $out/lib/paraver-kernel
    cp -p ${paraverKernelFast}/share/filters-config/* $out/share/filters-config
  '';
}
