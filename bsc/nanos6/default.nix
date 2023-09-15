{
  stdenv
, lib
, fetchFromGitHub
, automake
, autoconf
, libtool
, pkg-config
, numactl
, hwloc
, papi
, boost
, ovni
, enableDebug ? false
, enableJemalloc ? true
, jemalloc ? null
, cachelineBytes ? 64
, enableGlibcxxDebug ? false
, useGit ? false
, gitUrl ? "ssh://git@bscpm03.bsc.es/nanos6/nanos6"
, gitBranch ? "master"
, gitCommit ? "58712e669ac02f721fb841247361ea54f53a6a47"
}:

assert enableJemalloc -> (jemalloc != null);

with lib;

let
  release = rec {
    version = "3.0";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "nanos6";
      rev = "version-${version}";
      sha256 = "sha256-XEG8/8yQv5/OdSyK9Kig8xuWe6mTZ1eQKhXx3fXlQ1Y=";
    };
  };

  git = rec {
    version = src.shortRev;
    src = builtins.fetchGit {
      url = gitUrl;
      ref = gitBranch;
      rev = gitCommit;
    };
  };

  source = if (useGit) then git else release;
in
  stdenv.mkDerivation rec {
    pname = "nanos6";
    inherit (source) src version;

    prePatch = ''
      patchShebangs scripts/generate_config.sh
      patchShebangs autogen.sh
    '';

    enableParallelBuilding = true;

    preConfigure = ''
      export CACHELINE_WIDTH=${toString cachelineBytes}
      ./autogen.sh
    '' + lib.optionalString (useGit) ''
      export NANOS6_GIT_VERSION=${src.rev}
      export NANOS6_GIT_BRANCH=${gitBranch}
    '';

    configureFlags = [
      "--with-hwloc=${hwloc}"
      "--disable-all-instrumentations"
      "--enable-ovni-instrumentation"
      "--with-ovni=${ovni}"
    ] ++
      (optional enableJemalloc "--with-jemalloc=${jemalloc}") ++
      (optional enableGlibcxxDebug "CXXFLAGS=-D_GLIBCXX_DEBUG");

    postConfigure = lib.optionalString (!enableDebug) ''
      # Disable debug
      sed -i 's/\([a-zA-Z0-9_]*nanos6_debug[a-zA-Z0-9_]*\)\s*[+]\?=.*/\1 =/g' Makefile.am
    '';

    # The "bindnow" flags are incompatible with ifunc resolution mechanism. We
    # disable all by default, which includes bindnow.
    hardeningDisable = [ "all" ];

    # Keep debug symbols in the debug variant of the library
    dontStrip = enableDebug;

    buildInputs = [
      autoconf
      automake
      libtool
      pkg-config
      boost
      numactl
      hwloc
      papi
      ovni
    ];
  }
