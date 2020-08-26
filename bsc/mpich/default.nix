{
  stdenv
, fetchurl
, perl
, gfortran
, openssh
, hwloc
, libfabric
, enableDebug ? false
}:

with stdenv.lib;

stdenv.mkDerivation  rec {
  pname = "mpich";
  version = "3.3.2";

  src = fetchurl {
    url = "https://www.mpich.org/static/downloads/${version}/mpich-${version}.tar.gz";
    sha256 = "1farz5zfx4cd0c3a0wb9pgfypzw0xxql1j1294z1sxslga1ziyjb";
  };

  configureFlags = [
    "--enable-shared"
    "--enable-sharedlib"
    "--with-device=ch4:ofi"
    "--with-libfabric=${libfabric}"
  ]
  ++ optional enableDebug "--enable-g=dbg,log";

  enableParallelBuilding = true;

  buildInputs = [ perl gfortran openssh hwloc libfabric ];

  # doCheck = true; # Fails

  preFixup = ''
    # Ensure the default compilers are the ones mpich was built with
    sed -i 's:CC="gcc":CC=${stdenv.cc}/bin/gcc:' $out/bin/mpicc
    sed -i 's:CXX="g++":CXX=${stdenv.cc}/bin/g++:' $out/bin/mpicxx
    sed -i 's:FC="gfortran":FC=${gfortran}/bin/gfortran:' $out/bin/mpifort
  ''
  + stdenv.lib.optionalString (!stdenv.isDarwin) ''
    # /tmp/nix-build... ends up in the RPATH, fix it manually
    for entry in $out/bin/mpichversion $out/bin/mpivars; do
      echo "fix rpath: $entry"
      patchelf --set-rpath "$out/lib" $entry
    done
    '';

  meta = with stdenv.lib; {
    description = "Implementation of the Message Passing Interface (MPI) standard";

    longDescription = ''
      MPICH is a high-performance and widely portable implementation of
      the Message Passing Interface (MPI) standard (MPI-1, MPI-2 and MPI-3).
    '';
    homepage = "http://www.mpich.org";
    license = {
      url = "https://github.com/pmodels/mpich/blob/v${version}/COPYRIGHT";
      fullName = "MPICH license (permissive)";
    };
    maintainers = [ ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
