{ stdenv
, requireFile
, rpmextract
, libfabric
, patchelf
, gcc
, zlib
, autoPatchelfHook
, enableDebug ? false
}:

stdenv.mkDerivation rec {
  name = "intel-mpi-${version}";
  version = "2019.7.217";

  lib_variant = (if enableDebug then "debug" else "release");

  src = requireFile {
    name = "l_mpi_2019.7.217.tgz";
    sha256 = "01wwmiqff5lad7cdi8i57bs3kiphpjfv52sxll1w0jpq4c03nf4h";
    message = ''
      The package with Intel MPI cannot be redistributed freely, so you must do it
      manually. Go to:
      
      https://software.intel.com/content/www/us/en/develop/tools/mpi-library.html
      
      And register in order to download Intel MPI (is free of charge). Then you will
      be allowed to download it. Copy the url and use:
      
      nix-prefetch-url http://registrationcenter-download.intel.com/...../l_mpi_2019.7.217.tgz
      
      To add it to the store. Then try again building this derivation.
    '';
  };

  buildInputs = [
    rpmextract
    libfabric
    patchelf
    autoPatchelfHook
    gcc.cc.lib
    zlib
  ];

  postUnpack = ''
    pushd $sourceRoot
      rpmextract rpm/intel-mpi-*.rpm
    popd
  '';

  patches = [
    ./mpicc.patch
    ./mpicxx.patch
  ];

  postPatch = ''
    for i in bin/mpi* ; do
      sed -i "s:I_MPI_SUBSTITUTE_INSTALLDIR:$out:g" $i
    done     
  '';

  dontBuild = true;

  installPhase = ''
    cd opt/intel/compilers_and_libraries_2020.1.217/linux/mpi/intel64
    mkdir -p $out
    mv etc $out
    mv bin $out 
    mv include $out 
    mkdir $out/lib
    cp -a lib/lib* $out/lib
    cp -a lib/${lib_variant}_mt/lib* $out/lib
    rm $out/lib/libmpi.dbg
  '';
}
