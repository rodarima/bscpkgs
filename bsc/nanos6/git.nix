{
  stdenv
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
, enableJemalloc ? false
, jemalloc ? null
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  pname = "nanos6";
  version = "${src.shortRev}";
  branch = "master";
  cacheline-width = "64";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/nanos6/nanos6";
    ref = branch;
  };

  prePatch = ''
    patchShebangs scripts/generate_config.sh
  '';

  enableParallelBuilding = true;

  preConfigure = ''
    export CACHELINE_WIDTH=${cacheline-width}
    export NANOS6_GIT_VERSION=${src.rev}
    export NANOS6_GIT_BRANCH=${branch}
  '';

  configureFlags = [] ++
    optional enableJemalloc "--with-jemalloc=${jemalloc}";

  # The "bindnow" flags are incompatible with ifunc resolution mechanism. We
  # disable all by default, which includes bindnow.
  hardeningDisable = [ "all" ];

  buildInputs = [
    autoreconfHook
    autoconf
    automake
    libtool
    pkg-config
    perl
    boost
    numactl
    hwloc
    papi ]
    ++ (if (extrae != null) then [extrae] else []);
}
