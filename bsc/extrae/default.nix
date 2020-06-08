{ stdenv
, fetchurl
, boost
, libdwarf
, libelf
, libxml2
, libunwind
, papi
, binutils-unwrapped
, libiberty
, gcc
, gfortran
, xml2
#, mpi
, cuda ? null
#, withOpenmp ? false
}:

stdenv.mkDerivation rec {
  name = "extrae";
  version = "3.7.1";

  src = fetchurl {
    url = "https://ftp.tools.bsc.es/extrae/${name}-${version}-src.tar.bz2";
    sha256 = "0y036qc7y30pfj1mnb9nzv2vmxy6xxiy4pgfci6l3jc0lccdsgf8";
  };

  nativeBuildInputs = [ gcc gfortran libunwind ];

  buildInputs = [ binutils-unwrapped boost boost.dev libiberty
#  openmpi
  xml2 libxml2.dev ];

  patchPhase = ''
    sed -ie 's|/usr/bin/find|env find|g' substitute-all
    sed -ie 's|/bin/mv|env mv|g' substitute
  '';
    
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
      --without-mpi
      --without-dyninst)
  '';
#      --with-mpi=${mpi}
#      --with-mpi-headers=${mpi}/include
#      --with-mpi-libs=${mpi}/lib

#  ++ (
#    if (cuda != null)
#    then [ "--with-cuda=${cuda}" ]
#    else [ "--without-cuda" ]
#  )
#  ++ (
#    if (openmp)
#    then [ "--enable-openmp" ]
#    else []
#  );
}
