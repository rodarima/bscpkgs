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
, extrae
, boost
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  pname = "nanos6";
  version = "2.3.2";

  src = fetchurl {
    url = https://pm.bsc.es/ftp/ompss-2/releases/ompss-2-2019.11.2.tar.gz;
    sha256 = "03v1kpggdch25m1wfrdjl6crq252dgy6pms8h94d5jwcjh06fbf8";
  };

  enableParallelBuilding = true;
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
    ++ (if (extrae != null) then [extrae] else []);

}
