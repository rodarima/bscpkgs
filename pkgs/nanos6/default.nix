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
, jemallocNanos6 ? null
, cachelineBytes ? 64
, enableGlibcxxDebug ? false
, useGit ? false
, gitUrl ? "ssh://git@bscpm04.bsc.es/nanos6/nanos6"
, gitBranch ? "master"
, gitCommit ? "9f54c988e0a8b9c011d9d526acdb8d76f18fcae4"
}:

assert enableJemalloc -> (jemallocNanos6 != null);

with lib;

let
  release = rec {
    version = "4.2";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "nanos6";
      rev = "version-${version}";
      hash = "sha256-tBrRGLCjSFYdmVGPAC2DzYY6HJyZGUOMeykujafn7+4=";
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
  stdenv.mkDerivation (source // {
    pname = "nanos6";

    prePatch = ''
      patchShebangs scripts/generate_config.sh
      patchShebangs autogen.sh
    '';

    enableParallelBuilding = true;

    preConfigure = ''
      export CACHELINE_WIDTH=${toString cachelineBytes}
      ./autogen.sh
    '' + lib.optionalString (useGit) ''
      export NANOS6_GIT_VERSION=${gitCommit}
      export NANOS6_GIT_BRANCH=${gitBranch}
    '';

    configureFlags = [
      "--with-hwloc=${hwloc}"
      "--disable-all-instrumentations"
      "--enable-ovni-instrumentation"
      "--with-ovni=${ovni}"
    ] ++
      (optional enableJemalloc "--with-jemalloc=${jemallocNanos6}") ++
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
    separateDebugInfo = true;

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

    # Create a script that sets NANOS6_HOME
    postInstall = ''
      mkdir -p $out/nix-support
      echo "export NANOS6_HOME=$out" >> $out/nix-support/setup-hook
    ''; 

    meta = with lib; {
      homepage = "https://github.com/bsc-pm/nanos6";
      description = "Nanos6 runtime for OmpSs-2" +
        optionalString (enableDebug) " (with debug symbols)";
      platforms = platforms.linux;
      license = licenses.gpl3;
    };
  })
