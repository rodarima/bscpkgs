{
  stdenv
, fetchurl
, automake
, autoconf
, libtool
, pkg-config
, numactl
, hwloc
, papi
#, gnumake
, withExtrae ? false , extrae
, boost
}:

assert withExtrae -> extrae != null;

with stdenv.lib;

stdenv.mkDerivation rec {
  pname = "nanos6";
  version = "2.3.2";

  src = fetchurl {
    url = https://pm.bsc.es/ftp/ompss-2/releases/ompss-2-2019.11.2.tar.gz;
    sha256 = "03v1kpggdch25m1wfrdjl6crq252dgy6pms8h94d5jwcjh06fbf8";
  };

  preConfigure = ''
    cd ${pname}-${version}
    sed -i 's|/bin/echo|echo|g' loader/scripts/common.sh loader/scripts/lint/common.sh
    autoreconf -fiv
  '';

  #configureFlags = []
  #  ++ (if (extrae != null) then ["--with-extrae=${extrae}"] else [""]);

  buildInputs = [
    autoconf
    automake
    libtool
    pkg-config
    boost
    numactl
    hwloc
    papi ]
    ++ optional withExtrae extrae;

  buildPhase = ''
    make V=1 src/version/CodeVersionInfo.cpp
    make V=1
  '';
}
