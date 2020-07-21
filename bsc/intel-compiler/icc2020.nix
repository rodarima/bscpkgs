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

  # From Arch Linux PKGBUILD
  dir_nr="16526";
  year="2020";
  v_a="1";
  v_b="217";
  update="1";
  composer_xe_dir="compilers_and_libraries_${year}.${v_a}.${v_b}";
  tgz="parallel_studio_xe_2020_update${update}_cluster_edition.tgz";
  
  src = fetchurl {
    url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/${dir_nr}/${tgz}";
    sha256 = "1axblai5lmw9yqjaz7lvjraj5fsc7r37pklb9x3n1gdjfbgdh4gx";
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
