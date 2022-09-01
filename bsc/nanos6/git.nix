{
  stdenv
, lib
, automake
, autoconf
, libtool
, pkg-config
, perl
, numactl
, hwloc
, papi
, extrae
, boost
, autoreconfHook
, enableJemalloc ? true
, jemalloc ? null
, cachelineBytes ? 64
, enableGlibcxxDebug ? false
, gitUrl ? "ssh://git@bscpm03.bsc.es/nanos6/nanos6"
, gitBranch ? "master"
}:

with lib;

stdenv.mkDerivation rec {
  pname = "nanos6";
  version = "${src.shortRev}";

  src = builtins.fetchGit {
    url = gitUrl;
    ref = gitBranch;
  };

  prePatch = ''
    patchShebangs scripts/generate_config.sh
  '';

  enableParallelBuilding = true;
  dontStrip = true;

  preConfigure = ''
    export CACHELINE_WIDTH=${toString cachelineBytes}
    export NANOS6_GIT_VERSION=${src.rev}
    export NANOS6_GIT_BRANCH=${gitBranch}
  '';

  configureFlags = []
    ++ (optional enableJemalloc "--with-jemalloc=${jemalloc}")
    ++ (optional enableGlibcxxDebug "CXXFLAGS=-D_GLIBCXX_DEBUG");

  # The "bindnow" flags are incompatible with ifunc resolution mechanism. We
  # disable all by default, which includes bindnow.
  hardeningDisable = [ "all" ];

  buildInputs = [
    autoreconfHook
    autoconf
    automake
    libtool
    pkg-config
    boost
    numactl
    hwloc
    papi ]
    ++ (if (extrae != null) then [extrae] else []);
}
