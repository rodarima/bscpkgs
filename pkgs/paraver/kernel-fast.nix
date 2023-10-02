{
  stdenv
, autoreconfHook
, boost
, libxml2
, xml2
, wxpropgrid
, wxGTK28
, autoconf
, automake
}:

let
  wx = wxGTK28;
in
stdenv.mkDerivation rec {
  pname = "paraverKernelFast";
  version = "${src.shortRev}";
  
  src = builtins.fetchGit {
    url = "git@bscpm03.bsc.es:rpenacob/paraver-kernel.git";
    rev = "76f508095c35528ad89078473dc70b9600e507ff";
    ref = "fast";
  };

  hardeningDisable = [ "all" ];
  enableParallelBuilding = true;

  dontStrip = true;

  preConfigure = ''
    export CFLAGS="-O3 -DPARALLEL_ENABLED"
    export CXXFLAGS="-std=c++17 -O3 -DPARALLEL_ENABLED"
  '';

  configureFlags = [
    "--with-boost=${boost}"
    "--enable-openmp"
  ];
  
  buildInputs = [
    autoreconfHook
    boost
    libxml2.dev
    xml2
    autoconf
    automake
  ];
}
