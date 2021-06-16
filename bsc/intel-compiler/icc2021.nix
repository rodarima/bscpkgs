{ stdenv
, lib
, fetchurl
, dpkg
, rsync
, libffi
, libelf
, libxml2
, hwloc
, autoPatchelfHook
}:

with lib;

let

  getsrc = url: sha256: fetchurl { inherit url sha256; };

  version = "2021.2.0";
  _debpkgrel = "610";
  tbbrel = "357";

  # Shorhands
  main     = "intel-oneapi-dpcpp-cpp";
  compiler = "intel-oneapi-compiler-dpcpp-cpp";
  shared   = "intel-oneapi-compiler-shared";
  openmp   = "intel-oneapi-openmp";
  tbb      = "intel-oneapi-tbb";

  # From Arch Linux PKGBUILD:
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=intel-oneapi-compiler-dpcpp-cpp
  debs = [
    # From intel-oneapi-compiler-dpcpp-cpp
    "${main}-${version}-${version}-${_debpkgrel}_amd64.deb"
    "${compiler}-common-${version}-${version}-${_debpkgrel}_all.deb"
    "${compiler}-runtime-${version}-${version}-${_debpkgrel}_amd64.deb"

    # From intel-oneapi-compiler-shared
    "${shared}-${version}-${version}-${_debpkgrel}_amd64.deb"
    "${shared}-runtime-${version}-${version}-${_debpkgrel}_amd64.deb"
    "${shared}-common-${version}-${version}-${_debpkgrel}_all.deb"
    "${shared}-common-runtime-${version}-${version}-${_debpkgrel}_all.deb"
    "${compiler}-classic-fortran-shared-runtime-${version}-${version}-${_debpkgrel}_amd64.deb"

    # From intel-oneapi-openmp
    "${openmp}-${version}-${version}-${_debpkgrel}_amd64.deb"
    "${openmp}-common-${version}-${version}-${_debpkgrel}_all.deb"

    # From intel-oneapi-tbb
    "${tbb}-${version}-${version}-${tbbrel}_amd64.deb"
    "${tbb}-devel-${version}-${version}-${tbbrel}_amd64.deb"
    "${tbb}-common-${version}-${version}-${tbbrel}_all.deb"
    "${tbb}-common-devel-${version}-${version}-${tbbrel}_all.deb"
  ];

  apthost = "https://apt.repos.intel.com/oneapi/pool/main/";
  urls = map (x: apthost + x) debs;

  sums = [
    # From intel-oneapi-compiler-dpcpp-cpp
    "0pwsfzkazr9yf6v6lgwb3p2in6ch3rlcc9qcfarkyqn052p760kk"
    "0vzsanldhs4ym4gsfn0zjqm03x53ma1zjkj24hpkhpsvlr2r069w"
    "0nx62v6g0wl70lqdh7sh7gfgxbynhrrips9gpj9if60ngz6fm21m"

    # From intel-oneapi-compiler-shared
    "1al80pcy2r3q2r2pm04sva7rd3z6y287mkdv5jq4p5bfd8yi14d4"
    "07rp0cjmbgj48wly9dm6ibxzbsanmgrsjjqr7mx688ms6qbhv314"
    "1pf4xckyyhssjknhs6hwampjsz2qjlg81jw2fc441zaccwf25yf3"
    "0hk0x4wq60g9wnn9j051v25zcmbasjdzp34xfvrihmcvyws0s69g"
    "0dhbw8kshw4abqc9zf891z5ic0x13x3kvhk56nrqkqgcfwps9w8a"

    # From intel-oneapi-openmp
    "1wqy2sjwlqdh72zhfrxl9pm106hjzfdbbm98cxigbg20fb5lbv5a"
    "19nbqypvqcf8c3mwriaqrmp5igjpwvwrb9mq2fxa5i40w7bhlxjl"

    # From intel-oneapi-tbb
    "1dpii3g861kimky0x7dqcj6hg7zb6i5kw1wgwrxdc5yxhi5slbm9"
    "0bl1flm6w0w9nzrh34ig4p9qz2gbdgw9q14as2pwp8flicd8p899"
    "0w3kip6q713v1xlfc10ai4v15cbwmbqrv8r1f5x6pfqdbb0bpmbv"
    "0v95nmddyi0mjjdvm07w9fm3vq4a0wkx7zxlyzn2f4xg38qc5j73"
  ];

in
  stdenv.mkDerivation {
    inherit version;
    name = "intel-compiler-${version}";

    passthru = {
      CC = "icc";
      CXX = "icpc";
    };

    srcs = zipListsWith getsrc urls sums;

    buildInputs = [
      dpkg
      rsync
      libffi
      libelf
      libxml2
      hwloc
      autoPatchelfHook
    ];

    dontBuild = true;

    # The gcc package is required for building other programs
    #propagatedBuildInputs = [ gcc ];

    unpackCmd = ''
      dpkg -x $curSrc .
    '';

    # FIXME: Some dependencies are missing
    autoPatchelfIgnoreMissingDeps=true;

    # Compiler
    installPhase = ''
      mkdir -p $out/{bin,lib,include}

      pushd intel/oneapi/compiler/${version}/linux
        # Binaries
        rsync -a bin/ $out/bin/
        rsync -a bin/intel64/ $out/bin/

        # Libraries
        rsync -a --exclude=oclfpga lib/ $out/lib/
        rsync -a compiler/lib/intel64_lin/ $out/lib/

        # Headers
        rsync -a include/ $out/include/
        rsync -a compiler/include/ $out/include/
      popd

      # TBB
      pushd intel/oneapi/tbb/${version}
        # Libraries
        rsync -a lib/intel64/gcc4.8/ $out/lib/

        # Headers
        rsync -a include/ $out/include/
      popd
    '';

  }
