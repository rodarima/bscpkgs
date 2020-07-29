{ stdenv
, popt
}:

stdenv.mkDerivation rec {
  pname = "pscom";
  version = "5.4.6-1";

  src = builtins.fetchTarball {
    url = "https://github.com/ParaStation/${pname}/archive/${version}.tar.gz";
    sha256 = "1n9ic0j94iy09j287cfpfy0dd2bk17qakf1ml669jkibxbc5fqk8";
  };

  postPatch = ''
    patchShebangs ./
  '';

  buildInputs = [ popt ];
  preferLocalBuild = true;

  enableParallelBuilding = false;
}
