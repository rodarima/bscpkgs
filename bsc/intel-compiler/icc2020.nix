{ stdenv
, fetchurl
, rpmextract
, autoPatchelfHook
, gcc
, intel-mpi
}:

stdenv.mkDerivation rec {
  version = "${year}.${v_a}.${v_b}";
  name = "intel-compiler-${version}";

  passthru = {
    CC = "icc";
    CXX = "icpc";
  };

  # From Arch Linux PKGBUILD
  dir_nr="17114";
  year="2020";
  v_a="4";
  v_b="304";
  update="4";
  composer_xe_dir="compilers_and_libraries_${year}.${v_a}.${v_b}";
  tgz="parallel_studio_xe_2020_update${update}_professional_edition.tgz";

  src = fetchurl {
    url = "http://registrationcenter-download.intel.com/akdlm/IRC_NAS/tec/${dir_nr}/${tgz}";
    sha256 = "1rn9kk5bjj0jfv853b09dxrx7kzvv8dlyzw3hl9ijx9mqr09lrzr";
  };

  buildInputs = [
    rpmextract
    autoPatchelfHook
    gcc.cc.lib
    gcc
    intel-mpi
  ];

  # The gcc package is required for building other programs
  propagatedBuildInputs = [ gcc ];

  installPhase = ''
    pwd
    ls -l rpm
    rpmextract rpm/intel-icc-*.rpm
    rpmextract rpm/intel-comp-*.rpm
    rpmextract rpm/intel-c-comp-*.rpm
    rpmextract rpm/intel-openmp*.rpm
    rpmextract rpm/intel-ifort*.rpm

    mkdir -p $out/{bin,lib,include}

    pushd ./opt/intel/${composer_xe_dir}/linux/
      cp -a bin/intel64/* $out/bin/
      cp -a compiler/include/* $out/include/
      cp -a compiler/lib/intel64_lin/* $out/lib/
      ln -s lib $out/lib_lin
      rm $out/lib/*.dbg
    popd
  '';
}
