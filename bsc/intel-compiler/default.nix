{ stdenv
, fetchurl
}:

stdenv.mkDerivation rec {
  version = "2019.1.217";
  name = "intel-compiler-${version}";

  # From Arch Linux PKGBUILD
  dir_nr="16526";
  tgz="parallel_studio_xe_2020_update1_cluster_edition.tgz";
  
  src = fetchurl {
    url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/${dir_nr}/${tgz}";
    sha256 = "01wwmiqff5lad7cdi8i57bs3kiphpjfv52sxll1w0jpq4c03nf4h";
  };
}
