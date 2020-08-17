{ stdenv, fetchFromGitHub, perl, autoconf, automake
, libtool, flex, libevent, hwloc, munge, zlib
} :

let
  version = "2.2.4";

in stdenv.mkDerivation {
  pname = "pmix";
  inherit version;

  src = fetchFromGitHub {
    repo = "openpmix";
    owner = "openpmix";
    rev = "v${version}";
    sha256 = "1wc4sbnbg20lp6l6pk1sawrf5wrdajcijd1cmrpp1d6h9nv23ggv";
  };

  postPatch = ''
    patchShebangs ./autogen.pl
    patchShebangs ./config
  '';

  nativeBuildInputs = [ perl autoconf automake libtool flex ];

  buildInputs = [ libevent hwloc munge zlib ];

  configureFlags = [
    "--with-libevent=${libevent.dev}"
    "--with-munge=${munge}"
    "--with-hwloc=${hwloc.dev}"
  ];

  preConfigure = ''
    ./autogen.pl
  '';

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Process Management Interface for HPC environments";
    homepage = "https://openpmix.github.io/";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}

