{ stdenv, lib, fetchurl, pkgconfig, glib, libuuid, popt, elfutils, swig4, python3 }:

stdenv.mkDerivation rec {
  name = "babeltrace-1.5.8";

  src = fetchurl {
    url = "https://www.efficios.com/files/babeltrace/${name}.tar.bz2";
    sha256 = "1hkg3phnamxfrhwzmiiirbhdgckzfkqwhajl0lmr1wfps7j47wcz";
  };

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ glib libuuid popt elfutils swig4 python3 ];

  meta = with lib; {
    description = "Command-line tool and library to read and convert LTTng tracefiles";
    homepage = "https://www.efficios.com/babeltrace";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };

  configureFlags = [
    "--enable-python-bindings"
  ];
}
