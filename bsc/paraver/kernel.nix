{ stdenv
, fetchFromGitHub
, boost
, libxml2
, xml2
, fetchurl
, symlinkJoin
}:

stdenv.mkDerivation rec {
  pname = "paraver-kernel";
  version = "4.8.2";

  src = fetchurl {
    url = "https://ftp.tools.bsc.es/wxparaver/wxparaver-${version}-src.tar.bz2";
    sha256 = "0b8rrhnf7h8j72pj6nrxkrbskgg9b5w60nxi47nxg6275qvfq8hd";
  };

  postUnpack = "sourceRoot=$sourceRoot/src/paraver-kernel";

  enableParallelBuilding = true;

  preConfigure = ''
    configureFlagsArray=(
      "--with-boost=${boost}"
    )
  '';

  buildInputs = [
    boost
    xml2
    libxml2.dev
  ];

}
