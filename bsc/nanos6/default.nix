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
, enableJemalloc ? false
, jemalloc ? null
, cachelineBytes ? 64
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  pname = "nanos6";
  version = "2.5.1";

  src = fetchFromGitHub {
    owner = "bsc-pm";
    repo = "nanos6";
    rev = "version-${version}";
    sha256 = "17z6gr122cw0l4lsp0qdrdbcl1zcls4i0haxqpj3g60fvjx3fznp";
  };

  prePatch = ''
    patchShebangs scripts/generate_config.sh
  '';

  enableParallelBuilding = true;

  preConfigure = ''
    export CACHELINE_WIDTH=${toString cachelineBytes}
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
    boost
    numactl
    hwloc
    papi ]
    ++ (if (extrae != null) then [extrae] else []);

}
