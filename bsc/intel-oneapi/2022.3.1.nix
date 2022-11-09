{ stdenv
, fetchurl
, ncurses
, lib
, dpkg
, rsync
, libffi
, libelf
, libxml2
, hwloc
, autoPatchelfHook
}:

# The distribution of intel packages is a mess. We are doing the installation
# based on the .deb metapackage "intel-hpckit", and follow de dependencies,
# which have mismatching versions.

# Bruno Bzeznik (bzizou) went through the madness of using their .sh installer,
# pulling all the X dependencies here:
# https://github.com/Gricad/nur-packages/blob/4b67c8ad0ce1baa1d2f53ba41ae5bca8e00a9a63/pkgs/intel/oneapi.nix

# But this is an attempt to install the packages from the APT repo

let

  # Composite based on hpckit
  hpckit = { ver = "2022.2.0"; rev = "191"; };
  #basekit = { ver = "2022.2.0"; rev = "262"; };
  comp = { ver = "2022.0.2"; rev = "3658"; };
  mpi = { ver = "2021.6.0"; rev = "602"; };

  compilerRev = "3768";
  mpiRev = "76";
  debList = [
    "intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-${v}-${v}-${compilerRev}_amd64.deb"
    "intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-runtime-${v}-${v}-${compilerRev}_amd64.deb"
    "intel-oneapi-compiler-fortran-common-${v}-${v}-${compilerRev}_all.deb"
    "intel-oneapi-compiler-shared-${v}-${v}-${compilerRev}_amd64.deb"
    "intel-oneapi-compiler-cpp-eclipse-cfg-${v}-${compilerRev}_all.deb"
    "intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-common-${v}-${v}-${compilerRev}_all.deb"
    "intel-oneapi-compiler-dpcpp-cpp-classic-fortran-shared-runtime-${v}-${v}-${compilerRev}_amd64.deb"
    "intel-oneapi-compiler-dpcpp-cpp-common-${v}-${v}-${compilerRev}_all.deb"
    "intel-oneapi-compiler-fortran-runtime-${v}-${v}-${compilerRev}_amd64.deb"
    "intel-oneapi-compiler-shared-common-${v}-${v}-${compilerRev}_all.deb"
    "intel-oneapi-compiler-shared-runtime-${v}-${v}-${compilerRev}_amd64.deb"

    "intel-oneapi-dpcpp-cpp-${v}-${v}-${compilerRev}_amd64.deb"
    "intel-oneapi-openmp-${v}-${v}-${compilerRev}_amd64.deb"
    "intel-oneapi-openmp-common-${v}-${v}-${compilerRev}_all.deb"

    "intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-${v}-${compilerRev}_amd64.deb"
    "intel-oneapi-compiler-dpcpp-cpp-runtime-${v}-${v}-${compilerRev}_amd64.deb"
    "intel-oneapi-compiler-dpcpp-eclipse-cfg-${v}-${compilerRev}_all.deb"
    "intel-oneapi-compiler-dpcpp-cpp-${v}-${v}-${compilerRev}_amd64.deb"
    "intel-oneapi-compiler-fortran-${v}-${v}-${compilerRev}_amd64.deb"
    "intel-oneapi-compiler-fortran-runtime-${v}-${compilerRev}_amd64.deb"

    "intel-oneapi-mpi-devel-${mpi.ver}-${mpi.ver}-${mpi.rev}_amd64.deb"
    "intel-oneapi-mpi-${mpi.ver}-${mpi.ver}-${mpi.rev}_amd64.deb"

    #"intel-oneapi-tbb-${v}-${v}-${tbbVer}_amd64.deb"
    #"intel-oneapi-tbb-devel-${v}-${v}-${tbbVer}_amd64.deb"
    #"intel-oneapi-tbb-common-${v}-${v}-${tbbVer}_all.deb"
    #"intel-oneapi-tbb-common-devel-${v}-${v}-${tbbVer}_all.deb"

    #intel-basekit-2021.1.0
    #intel-hpckit-getting-started (>= 2021.1.0-2684)
    #intel-oneapi-common-vars (>= 2021.1.1-60)
    #intel-oneapi-common-licensing-2021.1.1 
    #intel-oneapi-dev-utilities-2021.1.1 
    #intel-oneapi-inspector (>= 2021.1.1-42)
    #intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-2021.1.1 
    #intel-oneapi-compiler-fortran-2021.1.1 
    #intel-oneapi-clck-2021.1.1 
    #intel-oneapi-itac-2021.1.1
  ];

  pkgsDesc = stdenv.mkDerivation {
    name = "intel-oneapi-packages";
    srcs = [
      (fetchurl {
        url = "https://apt.repos.intel.com/oneapi/dists/all/main/binary-amd64/Packages";
        sha256 = "sha256-swUGn097D5o1giK2l+3H4xFcUXSAUYtavQsPyiJlr2A=";
      })
      (fetchurl {
        url = "https://apt.repos.intel.com/oneapi/dists/all/main/binary-all/Packages";
        sha256 = "sha256-Ewpy0l0fXiJDG0FkAGykqizW1bm+/lcvI2OREyqzOLM=";
      })
    ];
    phases = [ "installPhase" ];
    installPhase = ''
      awk -F': ' '\
        BEGIN   { print "[ {" } \
        NR>1 && /^Package: / { print "} {"; } \
        /: /    { printf "%s = \"%s\";\n", $1, $2 } \
        END     { print "} ]" }' $srcs > $out
    '';
  };

  pkgsExpanded = import pkgsDesc;

  getSum = pkgs: deb:
  let
    matches = lib.filter (x: "pool/main/${deb}" == x.Filename) pkgs;
    match = assert lib.length matches == 1; lib.elemAt matches 0;
    #match = lib.elemAt matches 0;
  in
    match.SHA256;

  apthost = "https://apt.repos.intel.com/oneapi/pool/main/";
  urls = builtins.map (x: apthost + x) debList;
  sums = builtins.map (x: getSum pkgsExpanded x) debList;
  getsrc = url: sha256: fetchurl { inherit url sha256; };

  intel-oneapi-source = stdenv.mkDerivation rec {
    version = v;
    pname = "intel-oneapi-source";

    srcs = lib.zipListsWith getsrc urls sums;
    dontBuild = true;
    dontStrip = true;
    buildInputs = [ dpkg ];
    phases = [ "unpackPhase" "installPhase" ];

    unpackCmd = ''
      dpkg -x $curSrc .
    '';

    installPhase = ''
      mkdir -p $out
      mv intel $out
    '';
  };

in
  stdenv.mkDerivation rec {
    version = v;
    pname = "intel-oneapi";
    src = intel-oneapi-source;

    buildInputs = [
      rsync
      libffi
      libelf
      libxml2
      hwloc
      stdenv.cc.cc.lib
    ];
    nativeBuildInputs = [ autoPatchelfHook ];

    # The gcc package is required for building other programs
    #propagatedBuildInputs = [ gcc ];

    phases = [ "installPhase" "fixupPhase" ];

    dontStrip = true;

    installPhase = ''
      mkdir -p $out/{bin,lib,include}
      mkdir -p $out/share/man

      cd $src

      # Compiler
      pushd intel/oneapi/compiler/${version}
        pushd linux
          # Binaries
          rsync -a bin/ $out/bin/
          rsync -a bin/intel64/ $out/bin/
          rsync -a bin-llvm/ $out/bin-llvm/

          # Libraries
          rsync -a --exclude=oclfpga lib/ $out/lib/
          rsync -a compiler/lib/intel64_lin/ $out/lib/

          # Headers
          rsync -a include/ $out/include/
          rsync -a compiler/include/ $out/include/
        popd

        # Manuals
        rsync -a documentation/en/man/common/ $out/share/man/
      popd
    '';

  }






#in
#
#stdenv.mkDerivation rec {
#  version = "2022.3.2";
#  pkgVersion = "2022.3.1.16997"; # Intel (R) Versioning ???
#  pname = "intel-onapi-hpc-toolkit";
#
#  # From their CI: https://github.com/oneapi-src/oneapi-ci/blob/master/.github/workflows/build_all.yml
#  src = fetchurl {
#    url = "https://registrationcenter-download.intel.com/akdlm/irc_nas/18975/l_HPCKit_p_${pkgVersion}_offline.sh";
#    sha256 = "sha256-04TYMArgro1i+ONdiNZejripMNneUPS7Gj+MSfoGfWI=";
#  };
#
#  buildInputs = [ ncurses debs ];
#
#  unpackPhase = ''
#    sh $src -x
#    #sourceRoot=l_HPCKit_p_${pkgVersion}_offline
#  '';
#
#  # The gcc package is required for building other programs
#  #propagatedBuildInputs = [ gcc ];
#
#  installPhase = ''
#    mv l_HPCKit_p_${pkgVersion}_offline $out
#  '';
#}
