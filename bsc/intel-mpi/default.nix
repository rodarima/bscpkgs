{ stdenv
, rpmextract
, libfabric
, gcc
, zlib
, autoPatchelfHook
, enableDebug ? false
}:

stdenv.mkDerivation rec {
  name = "intel-mpi-${version}";
  version = "2019.7.217";
  dir_nr = "16546";

  lib_variant = (if enableDebug then "debug" else "release");

  src = builtins.fetchTarball {
    url = "http://registrationcenter-download.intel.com/akdlm/IRC_NAS/tec/${dir_nr}/l_mpi_${version}.tgz";
    sha256 = "19l995aavbn5lkiz9sxl6iwmjsrvjgjp14nn0qi1hjqs705db5li";
  };

  buildInputs = [
    rpmextract
    libfabric
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
    pushd opt/intel/compilers_and_libraries_2020.1.217/linux/mpi/intel64/bin
      for i in mpi* ; do
        echo "Fixing paths in $i"
        sed -i "s:I_MPI_SUBSTITUTE_INSTALLDIR:$out:g" "$i"
      done     
    popd
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
    ln -s . $out/intel64
    rm $out/lib/libmpi.dbg
  '';
}
