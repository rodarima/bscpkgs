{ stdenv
, fetchFromGitHub
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
, which
, mpi ? null
, cuda ? null
, llvmPackages
, autoreconfHook
, python37Packages
, installShellFiles
}:

stdenv.mkDerivation rec {
  name = "extrae";
  version = "3.8.3";

#  src = fetchurl {
#    url = "https://ftp.tools.bsc.es/extrae/${name}-${version}-src.tar.bz2";
#    sha256 = "0y036qc7y30pfj1mnb9nzv2vmxy6xxiy4pgfci6l3jc0lccdsgf8";
#  };

  src = fetchFromGitHub {
    owner = "rodarima";
    #owner = "bsc-performance-tools";
    repo = "extrae";
    rev = "a8ec6882c03d130f88b09f2114887101ca9f6b09";
    #rev = "${version}";
    sha256 = "02gwl17r63kica6lxycyn10a0r2ciycf6g3cdq5cna5zl351qf31";
  };

  enableParallelBuilding = true;

  nativeBuildInputs = [ installShellFiles ];

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
    which
    libxml2.dev
    python37Packages.sphinx
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

  # Install the manuals only by hand, as we don't want to pull the complete
  # LaTeX world
  postBuild = ''
    make -C docs man
  '';

  postInstall = ''
    installManPage docs/builds/man/*/*
  '';

#  ++ (
#    if (openmp)
#    then [ "--enable-openmp" ]
#    else []
#  );
}
