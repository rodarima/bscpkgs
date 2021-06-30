{
  stdenv
, fetchFromGitHub
, automake
, autoconf
, autoreconfHook
, libtool
, pkg-config
, numactl
, hwloc
, papi
, extrae
, boost
, babeltrace2
, enableJemalloc ? true
, jemalloc ? null
, cachelineBytes ? 64
, enableGlibcxxDebug ? false
}:

assert enableJemalloc -> (jemalloc != null);

with stdenv.lib;

stdenv.mkDerivation rec {
  pname = "nanos6";
  version = "2.6";

  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "nanos6";
    rev = "version-${version}";
    sha256 = "0rnbcjgsczqs4qqbm5w761f8h7fs1cw36akhjlbfazs5l92f0ac5";
  };

  prePatch = ''
    patchShebangs scripts/generate_config.sh
  '';

  enableParallelBuilding = true;

  preConfigure = ''
    export CACHELINE_WIDTH=${toString cachelineBytes}
  '';

  configureFlags = [ "--with-babeltrace2=${babeltrace2}" ] ++
    (optional enableJemalloc "--with-jemalloc=${jemalloc}") ++
    (optional enableGlibcxxDebug "CXXFLAGS=-D_GLIBCXX_DEBUG");

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
    papi
    babeltrace2
  ] ++ (if (extrae != null) then [extrae] else []);

}
