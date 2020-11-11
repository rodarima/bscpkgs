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
  pname = "extrae";
  version = "3.8.3";

  src = fetchFromGitHub {
    owner = "bsc-performance-tools";
    repo = "extrae";
    rev = "${version}";
    sha256 = "08ghd14zb3bgqb1smb824d621pqqww4q01n3pyws0vp3xi0kavf4";
  };

  # FIXME: Waiting for German to merge this patch
  patches = [ ./use-command.patch ];

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
