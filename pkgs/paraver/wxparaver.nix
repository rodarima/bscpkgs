{
  stdenv
, fetchFromGitHub
, boost
, libxml2
, xml2
, fetchurl
, wxGTK30-gtk3
, paraver-kernel
}:

let
  wx = wxGTK30-gtk3;
in
stdenv.mkDerivation rec {
  pname = "wxparaver";
  version = "4.8.2";

  src = fetchurl {
    url = "https://ftp.tools.bsc.es/wxparaver/wxparaver-${version}-src.tar.bz2";
    sha256 = "0b8rrhnf7h8j72pj6nrxkrbskgg9b5w60nxi47nxg6275qvfq8hd";
  };

  postUnpack = "sourceRoot=$sourceRoot/src/wxparaver";
  enableParallelBuilding = true;

  preConfigure = ''
    configureFlagsArray=(
      "--with-boost=${boost}"
      "--with-wx-config=${wx}/bin/wx-config"
      --with-wxpropgrid-dir=
      "--with-paraver=${paraver-kernel}"
      "--enable-debug=yes"
      "CXXFLAGS=-g"
      "CFLAGS=-g"
    )
  '';

  buildInputs = [
    boost
    xml2
    libxml2.dev
    wx
    paraver-kernel
  ];

}
