{
  stdenv
, lib
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
, ovni
, enableJemalloc ? true
, jemalloc ? null
, cachelineBytes ? 64
, enableGlibcxxDebug ? false
}:

assert enableJemalloc -> (jemalloc != null);

with lib;

stdenv.mkDerivation rec {
  pname = "nanos6";
  version = "2.8";

  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "nanos6";
    rev = "version-${version}";
    sha256 = "YGj/cubqXaNt4lR2CnSU+nXvi+SdB56EXLhfN/ufjHs=";
  };

  patches = [ ./fpic.patch ];

  prePatch = ''
    patchShebangs scripts/generate_config.sh
  '';

  enableParallelBuilding = true;

  preConfigure = ''
    export CACHELINE_WIDTH=${toString cachelineBytes}
  '';

  configureFlags = [
    "--with-babeltrace2=${babeltrace2}"
    "--with-ovni=${ovni}"
  ] ++
    (optional enableJemalloc "--with-jemalloc=${jemalloc}") ++
    (optional enableGlibcxxDebug "CXXFLAGS=-D_GLIBCXX_DEBUG");

  # The "bindnow" flags are incompatible with ifunc resolution mechanism. We
  # disable all by default, which includes bindnow.
  hardeningDisable = [ "all" ];

  # Keep debug symbols in the verbose variant of the library
  dontStrip = true;

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
    ovni
  ] ++ (if (extrae != null) then [extrae] else []);

}
