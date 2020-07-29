{ stdenv
, pscom
, perl
}:

stdenv.mkDerivation rec {
  pname = "psmpi";
  version = "5.4.6-1";

  src = builtins.fetchTarball {
    url = "https://github.com/ParaStation/${pname}/archive/${version}.tar.gz";
    sha256 = "1kr624216fz8pmfgbwdb3ks77pr6zhrssmn16j3pwaq5mkf3i9wc";
  };

  postPatch = ''
    patchShebangs ./
    echo "${version}" > VERSION
  '';

  preferLocalBuild = true;
  buildInputs = [ pscom ];
  nativeBuildInputs = [ perl ];
  #makeFlags = [ "V=1" ];

  configureFlags = [
    "--with-confset=default"
    "--with-threading"
    "--disable-fortran"
    "MPICH2_LDFLAGS=-lpsco"
  ];

  enableParallelBuilding = false;
}
