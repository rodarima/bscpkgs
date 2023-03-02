{ stdenv
, lib
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
, symlinkJoin
}:

let
  libdwarfBundle = symlinkJoin {
    name = "libdwarfBundle";
    paths = [ libdwarf.dev libdwarf.lib libdwarf.out ];
  };
in

stdenv.mkDerivation rec {
  pname = "extrae";
  version = "4.0.1";
  src = fetchFromGitHub {
    owner = "bsc-performance-tools";
    repo = "extrae";
    rev = "${version}";
    sha256 = "SlMYxNQXJ0Xg90HmpnotUR3tEPVVBXhk1NtEBJwGBR4=";
  };

  patches = [
    # FIXME: Waiting for German to merge this patch. Still not in master, merged
    # on 2023-03-01 in devel branch (after 3 years), see:
    # https://github.com/bsc-performance-tools/extrae/pull/45
    ./use-command.patch
    # https://github.com/bsc-performance-tools/extrae/issues/71
    ./PTR.patch
  ];

  enableParallelBuilding = true;
  hardeningDisable = [ "all" ];

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
    #python37Packages.sphinx
  ]
  ++ lib.optional stdenv.cc.isClang llvmPackages.openmp;
    
  preConfigure = ''
    configureFlagsArray=(
      --enable-posix-clock
      --with-binutils="${binutils-unwrapped} ${libiberty}"
      --with-dwarf=${libdwarfBundle}
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

  # FIXME: sphinx is broken
  #postBuild = ''
  #  make -C docs man
  #'';
  #
  #postInstall = ''
  #  installManPage docs/builds/man/*/*
  #'';

#  ++ (
#    if (openmp)
#    then [ "--enable-openmp" ]
#    else []
#  );
}
