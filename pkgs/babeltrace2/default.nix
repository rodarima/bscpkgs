{
  stdenv
, fetchurl
, pkg-config
, glib
, libuuid
, popt
, elfutils
, python3
, swig4
, ncurses
, breakpointHook
}:

stdenv.mkDerivation rec {
  pname = "babeltrace2";
  version = "2.0.3";

  src = fetchurl {
    url = "https://www.efficios.com/files/babeltrace/${pname}-${version}.tar.bz2";
    sha256 = "1804pyq7fz6rkcz4r1abkkn0pfnss13m6fd8if32s42l4lajadm5";
  };

  enableParallelBuilding = true;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ glib libuuid popt elfutils python3 swig4 ncurses breakpointHook ];
  hardeningDisable = [ "all" ];

  configureFlags = [
    "--enable-python-plugins"
    "--enable-python-bindings"
  ];

}
