{
  fetchgit
, stdenv
, cmake
, qtbase
, qttools
, qtcharts
, libGLU
, libGL
, glm
, glew
, wrapQtAppsHook
, otf ? null
}:

with lib;

# ViTE 1.1 has several bugs, so use the SVN version.
let
  #rev = "1543";
  #externals = fetchsvn {
  #  url = "svn://scm.gforge.inria.fr/svn/vite/externals";
  #  sha256 = "1a422n3dp72v4visq5b1i21cf8sj12903sgg5v2hah3sgk02dnyz";
  #  inherit rev;
  #};
in
stdenv.mkDerivation rec {
  version = "c6c0ce7";
  pname = "vite";

  #dontStrip = true;
  #enableDebugging = true;
  preferLocalBuild = true;

  #src = ./../../vite-c6c0ce7;
  src = fetchgit {
    url = "https://gitlab.inria.fr/solverstack/vite.git";
    sha256 = "17h57jjcdynnjd6s19hs6zdgvr9j7hj1rf6a62d9qky8wzb78y37";
    #rev = "373d4a8ebe86aa9ed07c9a8eb5e5e7f1602baef9";
    rev = "c6c0ce7a75324f03b24243397dfaa0d3bcd5bd1b";
  };

  #patches = [ ./cmake.patch ];

  #preConfigure = ''
  #  rm -rv externals
  #  ln -sv "${externals}" externals
  #'';

  buildInputs = [
    cmake qtbase qttools qtcharts
    libGLU libGL glm glew wrapQtAppsHook
  ] ++ optional (otf != null) otf;

  #NIX_LDFLAGS = "-lGLU";

  cmakeFlags = [
  #  "-DCMAKE_BUILD_TYPE=Debug"
    #"-DVITE_ENABLE_OTF2=True"
    #"-DVITE_ENABLE_TAU=True"
  ]
  ++ optionals (otf != null)
  [
    "-DVITE_ENABLE_OTF=True"
    "-DOTF_LIBRARY_DIR=${otf}/lib"
    "-DOTF_INCLUDE_DIR=${otf}/include"
  ];

  meta = {
    description = "Visual Trace Explorer (ViTE), a tool to visualize execution traces";

    longDescription = ''
      ViTE is a trace explorer. It is a tool to visualize execution
      traces in Pajé or OTF format for debugging and profiling
      parallel or distributed applications.
    '';

    homepage = "http://vite.gforge.inria.fr/";
    license = lib.licenses.cecill20;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.linux;
  };
}
