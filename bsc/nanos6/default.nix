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
  version = "2.4";

  src = fetchurl {
    url = "https://pm.bsc.es/ftp/ompss-2/releases/ompss-2-2020.06.tar.gz";
    sha256 = "0f9hy2avblv31wi4910x81wc47dwx8x9nd72y02lgrhl7fc9i2sf";
  };

  enableParallelBuilding = false;
  preConfigure = ''
    cd ${pname}-${version}
    sed -i 's|/bin/echo|echo|g' loader/scripts/common.sh loader/scripts/lint/common.sh
  '';

  configureFlags = [
    "--with-symbol-resolution=indirect"
  ];

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
