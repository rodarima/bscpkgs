{ stdenv
, rpmextract
, gcc
, zlib
, ucx
, numactl
, rdma-core
, libpsm2
, patchelf
, autoPatchelfHook
, enableDebug ? false
}:

stdenv.mkDerivation rec {
  name = "intel-mpi-${version}";
  version = "2019.8.254";
  dir_nr = "16814";
  internal-ver = "2020.2.254";

  lib_variant = (if enableDebug then "debug" else "release");

  src = builtins.fetchTarball {
    url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/${dir_nr}/l_mpi_${version}.tgz";
    sha256 = "1za4zyvxm5bfkrca843na6sxq2gq7qb87s0zysa7dnyqjwa11n45";
  };

  buildInputs = [
    rpmextract
    autoPatchelfHook
    gcc.cc.lib
    zlib
    ucx
    numactl
    rdma-core
    libpsm2
    patchelf
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
    pushd opt/intel/compilers_and_libraries_${internal-ver}/linux/mpi/intel64/bin
      for i in mpi* ; do
        echo "Fixing paths in $i"
        sed -i "s:I_MPI_SUBSTITUTE_INSTALLDIR:$out:g" "$i"
      done     
    popd
  '';

  dontBuild = true;

  installPhase = ''
    cd opt/intel/compilers_and_libraries_${internal-ver}/linux/mpi/intel64
    mkdir -p $out
    mv etc $out
    mv bin $out 
    mv include $out 
    mkdir $out/lib
    cp -a lib/lib* $out/lib
    cp -a lib/${lib_variant}_mt/lib* $out/lib
    cp -a libfabric/lib/* $out/lib
    cp -a libfabric/lib/prov/* $out/lib
    cp -a libfabric/bin/* $out/bin
    ln -s . $out/intel64
    rm $out/lib/libmpi.dbg

    # Fixup Intel PSM2 library missing (now located at PSMX2)
    ln -s $out/lib/libpsmx2-fi.so $out/lib/libpsm2-fi.so
  '';

  dontAutoPatchelf = true;

  # The rpath of libfabric.so bundled with Intel MPI is patched to include the
  # rdma-core lib path, as is required for dlopen to find the rdma components.
  # TODO: Try the upstream libfabric library with rdma support, so we can avoid
  # this hack.
  postFixup = ''
    autoPatchelf -- $out
    patchelf --set-rpath "$out/lib:${rdma-core}/lib:${libpsm2}/lib" $out/lib/libfabric.so
    echo "Patched RPATH in libfabric.so to: $(patchelf --print-rpath $out/lib/libfabric.so)"
  '';
}
