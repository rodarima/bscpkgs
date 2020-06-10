{ stdenv
, fetchgit
, boost
, libdwarf
, libelf
, libxml2
, libunwind
, papi
, binutils-unwrapped
, libiberty
, gfortran
, xml2
, mpi ? null
, cuda ? null
, llvmPackages
, autoreconfHook
}:

stdenv.mkDerivation rec {
  name = "extrae";
  version = "3.7.1";

#  src = fetchurl {
#    url = "https://ftp.tools.bsc.es/extrae/${name}-${version}-src.tar.bz2";
#    sha256 = "0y036qc7y30pfj1mnb9nzv2vmxy6xxiy4pgfci6l3jc0lccdsgf8";
#  };

  # Use patched Extrae version
  src = fetchgit {
    url = "https://github.com/rodarima/extrae";
    rev = "15883516d6bd802e5b76ff28c4b4a3a5cb113880";
    sha256 = "1hmf6400kw5k3j6xdbbd0yw4xhrjhk1kibp6m7r2i000qjgha8v6";
  };

  enableParallelBuilding = true;

  buildInputs = [
    autoreconfHook
    gfortran
    libunwind
    binutils-unwrapped
    boost
    boost.dev
    libiberty
    mpi
    xml2
    libxml2.dev
  ]
  ++ stdenv.lib.optional stdenv.cc.isClang llvmPackages.openmp;
    
  preConfigure = ''
    configureFlagsArray=(
      --enable-posix-clock
      --with-binutils="${binutils-unwrapped} ${libiberty}"
      --with-dwarf=${libdwarf}
      --with-elf=${libelf}
      --with-boost=${boost.dev}
      --enable-instrument-io
      --enable-instrument-dynamic-memory
      --without-memkind
      --enable-merge-in-trace
      --disable-online
      --without-opencl
      --enable-pebs-sampling
      --enable-sampling
      --with-unwind=${libunwind.dev}
      --with-xml-prefix=${libxml2.dev}
      --with-papi=${papi}
      ${if (mpi != null) then ''--with-mpi=${mpi}''
        else ''--without-mpi''}
      --without-dyninst)
  '';

#  ++ (
#    if (openmp)
#    then [ "--enable-openmp" ]
#    else []
#  );
}
