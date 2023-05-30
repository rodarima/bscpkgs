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
, enableJemalloc ? true
, jemalloc ? null
, cachelineBytes ? 64
, enableGlibcxxDebug ? false
}:

assert enableJemalloc -> (jemalloc != null);

with lib;

stdenv.mkDerivation rec {
  pname = "nanos6";
  version = "3.0";

  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "nanos6";
    rev = "version-${version}";
    sha256 = "sha256-XEG8/8yQv5/OdSyK9Kig8xuWe6mTZ1eQKhXx3fXlQ1Y=";
  };

  prePatch = ''
    patchShebangs scripts/generate_config.sh
    patchShebangs autogen.sh
  '';

  enableParallelBuilding = true;

  preConfigure = ''
    export CACHELINE_WIDTH=${toString cachelineBytes}
    ./autogen.sh
  '';

  configureFlags = [
    "--with-hwloc=${hwloc}"
    "--disable-all-instrumentations"
    "--enable-ovni-instrumentation"
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
