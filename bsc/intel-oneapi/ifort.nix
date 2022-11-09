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
, zlib
, autoPatchelfHook
, symlinkJoin
, libfabric
, gcc
, wrapCCWith
}:

# The distribution of intel packages is a mess. We are doing the installation
# based on the .deb metapackage "intel-hpckit", and follow de dependencies,
# which have mismatching versions.

# Bruno Bzeznik (bzizou) went through the madness of using their .sh installer,
# pulling all the X dependencies here:
# https://github.com/Gricad/nur-packages/blob/4b67c8ad0ce1baa1d2f53ba41ae5bca8e00a9a63/pkgs/intel/oneapi.nix

# But this is an attempt to install the packages from the APT repo

let

  # As of 2022-11-10 this is the last release for hpckit and all other
  # components
  v = {
    hpckit   = "2022.3.0";
    compiler = "2022.2.0";
    tbb      = "2021.7.1";
    mpi      = "2021.7.0";
  };

  aptPackageIndex = stdenv.mkDerivation {
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

  aptPackages = import aptPackageIndex;

  apthost = "https://apt.repos.intel.com/oneapi/";

  getSum = pkgList: name:
  let
    matches = lib.filter (x: name == x.Package) pkgList;
    #n = lib.length matches;
    #match = builtins.trace (name + " -- ${builtins.toString n}") (lib.elemAt matches 0);
    match = lib.elemAt matches 0;
  in
    match.SHA256;

  getUrl = pkgList: name:
  let
    matches = lib.filter (x: name == x.Package) pkgList;
    match = assert lib.length matches == 1; lib.elemAt matches 0;
    #n = lib.length matches;
    #match = builtins.trace (name + " -- ${builtins.toString n}") (lib.elemAt matches 0);
  in
    apthost + match.Filename;

  uncompressDebs = debs: name: stdenv.mkDerivation {
    name = name;
    srcs = debs;
    buildInputs = [ dpkg ];
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out
      for src in $srcs; do
        echo "unpacking $src"
        dpkg -x $src $out
      done
    '';
  };

  joinDebs = name: names:
  let
    urls = builtins.map (x: getUrl aptPackages x) names;
    sums = builtins.map (x: getSum aptPackages x) names;
    getsrc = url: sha256: fetchurl { inherit url sha256; };
    debs = lib.zipListsWith getsrc urls sums;
  in
    uncompressDebs debs "${name}-source";


  intel-mpi = stdenv.mkDerivation rec {
    version = v.mpi;
    pname = "intel-mpi";

    src = joinDebs pname [
      "intel-oneapi-mpi-devel-${version}"
      "intel-oneapi-mpi-${version}"
    ];

    buildInputs = [
      rsync
      libfabric
      zlib
      stdenv.cc.cc.lib
    ];

    nativeBuildInputs = [ autoPatchelfHook ];
    phases = [ "installPhase" "fixupPhase" ];
    dontStrip = true;
    installPhase = ''
      mkdir -p $out/{bin,etc,lib,include}
      mkdir -p $out/share/man

      cd $src

      # MPI
      pushd opt/intel/oneapi/mpi/${version}
        rsync -a man/ $out/share/man/
        rsync -a etc/ $out/etc/
        rsync -a include/ $out/include/
        rsync -a lib/ $out/lib/
        # Broken due missing libze_loader.so.1
        rsync -a --exclude IMB-MPI1-GPU bin/ $out/bin/
      popd
    '';
  };

  intel-tbb = stdenv.mkDerivation rec {
    version = v.tbb;
    pname = "intel-tbb";
    src = joinDebs pname [
      "intel-oneapi-tbb-${version}"
      "intel-oneapi-tbb-common-${version}"
    ];

    buildInputs = [
      intel-mpi
      rsync
      libffi
      libelf
      libxml2
      hwloc
      stdenv.cc.cc.lib
    ];

    nativeBuildInputs = [ autoPatchelfHook ];
    phases = [ "installPhase" "fixupPhase" ];
    dontStrip = true;

    autoPatchelfIgnoreMissingDeps = [ "libhwloc.so.5" ];

    installPhase = ''
      mkdir -p $out/lib

      cd $src

      pushd opt/intel/oneapi/tbb/${version}
        # Libraries
        rsync -a lib/intel64/gcc4.8/ $out/lib/
      popd
    '';
  };

  intel-compiler-shared = stdenv.mkDerivation rec {
    version = v.compiler;
    pname = "intel-compiler-shared";
    src = joinDebs pname [
      "intel-oneapi-compiler-shared-${version}"
      "intel-oneapi-compiler-shared-common-${version}"
      "intel-oneapi-compiler-shared-runtime-${version}"
    ];

    buildInputs = [
      intel-mpi
      intel-tbb
      rsync
      libffi
      libelf
      libxml2
      hwloc
      stdenv.cc.cc.lib
    ];

    nativeBuildInputs = [ autoPatchelfHook ];
    phases = [ "installPhase" "fixupPhase" ];
    dontStrip = true;

    autoPatchelfIgnoreMissingDeps = [ "libsycl.so.5" ];

    installPhase = ''
      mkdir -p $out/{bin,lib,include}
      mkdir -p $out/share/man

      cd $src

      # Compiler
      pushd opt/intel/oneapi/compiler/${version}
        pushd linux
          # Binaries
          rsync -a bin/ $out/bin/
          rsync -a --exclude libcilkrts.so.5 bin/intel64/ $out/bin/

          # Libraries
          rsync -a lib/ $out/lib/
          rsync -a compiler/lib/intel64_lin/ $out/lib/
          chmod +w $out/lib
          cp bin/intel64/libcilkrts.so.5 $out/lib/
          ln -s $out/lib/libcilkrts.so.5 $out/lib/libcilkrts.so

          # Headers
          rsync -a compiler/include/ $out/include/
        popd
      popd
    '';
  };


  intel-compiler-fortran = stdenv.mkDerivation rec {
    version = v.compiler;
    pname = "intel-fortran";
    src = joinDebs pname [
      "intel-oneapi-compiler-fortran-${version}"
      "intel-oneapi-compiler-fortran-common-${version}"
      "intel-oneapi-compiler-fortran-runtime-${version}"

      "intel-oneapi-compiler-dpcpp-cpp-classic-fortran-shared-runtime-${version}"
      #"intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-${version}"
      #"intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-runtime-${version}"
    ];

    buildInputs = [
      intel-mpi
      intel-compiler-shared
      rsync
      libffi
      libelf
      libxml2
      hwloc
      stdenv.cc.cc.lib
    ];

    nativeBuildInputs = [ autoPatchelfHook ];

    # The gcc package is required for building other programs
    propagatedBuildInputs = [ stdenv.cc intel-compiler-shared ];

    phases = [ "installPhase" "fixupPhase" ];

    dontStrip = true;

    installPhase = ''
      mkdir -p $out/{bin,lib,include}
      mkdir -p $out/share/man

      cd $src

      # Compiler
      pushd opt/intel/oneapi/compiler/${version}
        pushd linux
          # Binaries
          rsync -a bin/ $out/bin/
          rsync -a bin/intel64/ $out/bin/

          # Libraries
          rsync -a lib/ $out/lib/
          rsync -a compiler/lib/intel64_lin/ $out/lib/

          # Headers
          rsync -a compiler/include/ $out/include/
        popd

        # Manuals
        rsync -a documentation/en/man/common/ $out/share/man/

        # Fix lib_lin
        ln -s $out/lib $out/lib_lin
      popd
    '';
  };


  intel-compiler-classic = stdenv.mkDerivation rec {
    version = v.compiler;
    pname = "intel-compiler-classic";
    src = joinDebs pname [
      "intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-${version}"
      "intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-runtime-${version}"
      "intel-oneapi-compiler-dpcpp-cpp-classic-fortran-shared-runtime-${version}"
      "intel-oneapi-dpcpp-cpp-${version}"
      "intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-common-${version}"
    ];

    buildInputs = [
      intel-compiler-shared
      rsync
      libffi
      libelf
      libxml2
      hwloc
      stdenv.cc.cc.lib
    ];

    nativeBuildInputs = [ autoPatchelfHook ];

    # The gcc package is required for building other programs
    propagatedBuildInputs = [ stdenv.cc intel-compiler-shared ];

    phases = [ "installPhase" "fixupPhase" ];

    dontStrip = true;

    installPhase = ''
      mkdir -p $out/{bin,lib}
      mkdir -p $out/share/man

      cd $src

      # Compiler
      pushd opt/intel/oneapi/compiler/${version}
        pushd linux
          # Binaries
          rsync -a bin/ $out/bin/
          rsync -a bin/intel64/ $out/bin/

          # Libraries
          rsync -a --exclude oclfpga lib/ $out/lib/
        popd

        # Manuals
        rsync -a documentation/en/man/common/ $out/share/man/
      popd
    '';
  };

  intel-compiler-classic-wrapper = 
    let
      targetConfig = stdenv.targetPlatform.config;
      inherit gcc;
    in wrapCCWith rec {
      cc = intel-compiler-classic;
      extraBuildCommands = ''
        echo "-B${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-cflags
        echo "-isystem ${cc}/include" >> $out/nix-support/cc-cflags
        echo "-isystem ${cc}/include/intel64" >> $out/nix-support/cc-cflags
        echo "-L${gcc.cc}/lib/gcc/${targetConfig}/${gcc.version}" >> $out/nix-support/cc-ldflags
        echo "-L${gcc.cc.lib}/lib" >> $out/nix-support/cc-ldflags
        echo "-L${intel-compiler-shared}/lib" >> $out/nix-support/cc-ldflags

        cat "${cc}/nix-support/propagated-build-inputs" >> \
          $out/nix-support/propagated-build-inputs

        # Create the wrappers for icc and icpc
        wrap icc  $wrapper $ccPath/icc
        wrap icpc $wrapper $ccPath/icpc
        wrap mcpcom $wrapper $ccPath/mcpcom
      '';
    };

in
  {
    inherit
      intel-compiler-classic
      intel-compiler-classic-wrapper
      intel-compiler-fortran
      intel-compiler-shared;
  }
