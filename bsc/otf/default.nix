{
  stdenv
#, mkDerivation
, fetchurl
}:

stdenv.mkDerivation rec {
  version = "1.2.18";
  pname = "otf";
  src = fetchurl {
    url =
"http://paratools01.rrp.net/wp-content/uploads/2016/06/OTF-SRC-${version}.tar.gz";
    sha256 = "10k1hyyn6w4lf5kbn1krfacaspvn1xg3qgn4027xal3hjf3kkxap";
  };

  patches = [ ./printf.patch ];
}
