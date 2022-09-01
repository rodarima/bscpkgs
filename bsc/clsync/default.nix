{ stdenv
, fetchFromGitHub
, libcap
, libcgroup
, libmhash
, doxygen
, graphviz
, autoreconfHook
, pkg-config
, glib
}:

let
  version = "0.4.4";

in stdenv.mkDerivation {
  pname = "clsync";
  inherit version;

  src = fetchFromGitHub {
    repo = "clsync";
    owner = "clsync";
    rev = "v${version}";
    sha256 = "0sdiyfwp0iqr6l1sirm51pirzmhi4jzgky5pzfj24nn71q3fwqgz";
  };

  outputs = [ "out" "dev" ];

  buildInputs = [
    autoreconfHook
    libcap
    libcgroup
    libmhash
    doxygen
    graphviz
    pkg-config
    glib
  ];

  preConfigure = ''
    ./configure --help
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "File live sync daemon based on inotify/kqueue/bsm (Linux, FreeBSD), written in GNU C";
    homepage = "https://github.com/clsync/clsync";
    license = licenses.gpl3Plus;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}

