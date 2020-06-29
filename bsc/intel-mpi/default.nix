{ stdenv
, requireFile
, rpmextract
, libfabric
, patchelf
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

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    rpmextract rpm/intel-mpi-*.rpm
    cd opt/intel/compilers_and_libraries_2020.1.217/linux/mpi/intel64

    for i in bin/mpi* ; do
      sed -i "s:I_MPI_SUBSTITUTE_INSTALLDIR:$out:g" $i
    done     

    mv etc $out
    mv bin $out 
    mv include $out 

    mkdir $out/lib
    cp -a lib/lib* $out/lib
    cp -a lib/${lib_variant}_mt/lib* $out/lib


  '';

  preFixup = ''
    echo $out/lib contains:
    ls -l $out/lib
    echo ----------------------
    find $out/bin -type f -executable -exec \
      patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      '{}' \;
    
    find $out/lib -name '*.so' -exec \
      patchelf --set-rpath "$out/lib:${stdenv.cc}/lib:${stdenv.glibc}/lib:${libfabric}/lib" '{}' \;
  '';

  buildInputs = [
    rpmextract
    libfabric
    patchelf
  ];
}
