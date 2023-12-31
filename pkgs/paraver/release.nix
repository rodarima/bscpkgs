{
  stdenv
, lib
, fetchFromGitHub
, boost
, libxml2
, xml2
, fetchurl
, wxGTK32
, autoconf
, automake
, openssl # For boost
# Custom patches :)
, enableMouseLabel ? false
}:

with lib;

let
  wx = wxGTK32;
in
stdenv.mkDerivation rec {
  pname = "wxparaver";
  version = "4.10.6";

  src = fetchurl {
    url = "https://ftp.tools.bsc.es/wxparaver/wxparaver-${version}-src.tar.bz2";
    sha256 = "a7L15viCXtQS9vAsdFzCFlUavUzl4Y0yOYmVSCrdWBU=";
  };

  patches = []
    ++ optional (enableMouseLabel) ./mouse-label.patch;

  enableParallelBuilding = true;

  # What would we do without the great gamezelda:
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=wxparaver
  postPatch = ''
    pushd src/wxparaver
      sed -i \
	  -e 's|-lparaver-api -lparaver-kernel|-L../../paraver-kernel/src/.libs -L../../paraver-kernel/api/.libs -lparaver-api -lparaver-kernel -lssl -lcrypto -ldl|g' \
	  -e '$awxparaver_bin_CXXFLAGS = @CXXFLAGS@ -I../../paraver-kernel -I../../paraver-kernel/api' \
	  src/Makefile.am

      sed -i 's| -L$PARAVER_LIBDIR||g' configure.ac
    popd

    # Patch shebang as /usr/bin/env is missing in nix
    sed -i '1c#!/bin/sh' src/paraver-cfgs/install.sh
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
  ];

  buildInputs = [
    boost
    xml2
    libxml2.dev
    wx
    autoconf
    automake
    openssl.dev
  ];

}
