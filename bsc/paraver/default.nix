{
  stdenv
, lib
, fetchFromGitHub
, boost
, libxml2
, xml2
, fetchurl
, wxGTK28
, autoconf
, automake
, wxpropgrid
# Custom patches :)
, enableMouseLabel ? false
}:

with lib;

let
  wx = wxGTK28;
in
stdenv.mkDerivation rec {
  pname = "wxparaver";
  version = "4.8.2";

  src = fetchurl {
    url = "https://ftp.tools.bsc.es/wxparaver/wxparaver-${version}-src.tar.bz2";
    sha256 = "0b8rrhnf7h8j72pj6nrxkrbskgg9b5w60nxi47nxg6275qvfq8hd";
  };

  patches = []
    ++ optional (enableMouseLabel) ./mouse-label.patch;

  enableParallelBuilding = true;

  # What would we do without the great gamezelda:
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=wxparaver
  postPatch = ''
    pushd src/wxparaver
      sed -i 's|-lparaver-kernel -lparaver-api|-L../../paraver-kernel/src/.libs -L../../paraver-kernel/api/.libs -lparaver-kernel -lparaver-api|g' src/Makefile.am
      sed -i 's|^wxparaver_bin_CXXFLAGS =.*|& -I../../paraver-kernel -I../../paraver-kernel/api|' src/Makefile.am
      sed -i 's| -L$PARAVER_LIBDIR||g' configure.ac
    popd

    # Patch shebang as /usr/bin/env is missing in nix
    sed -i '1c#!/bin/sh' src/paraver-cfgs/install.sh

    #sed -i '1524d' src/wxparaver/src/gtimeline.cpp
    #sed -i '806d' src/wxparaver/src/gtimeline.cpp
    #sed -i '142d' src/wxparaver/src/paravermain.cpp
  '';
  #TODO: Move the sed commands to proper patches (and maybe send them upstream?)

  preConfigure = ''
    pushd src/wxparaver
      autoreconf -i -f
    popd
  '';

  configureFlags = [
    "--with-boost=${boost}"
    "--with-wx-config=${wx}/bin/wx-config"
    "--with-wxpropgrid-dir=${wxpropgrid}"
  ];

  buildInputs = [
    boost
    xml2
    libxml2.dev
    wx
    autoconf
    automake
  ];

}
