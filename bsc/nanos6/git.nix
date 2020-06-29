{
  stdenv
, automake
, autoconf
, libtool
, pkg-config
, numactl
, hwloc
, papi
, extrae
, boost
, autoreconfHook
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  pname = "nanos6";
  version = "2.4-nix-526b0e14";
  branch = "master";
  cacheline-width = "64";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/rarias/nanos6";
    rev = "526b0e1418e445115d79cca402a387a88ea61bb9";
    ref = branch;
  };

  enableParallelBuilding = true;
  patchPhase = ''
    export NANOS6_GIT_VERSION=${src.rev}
    export NANOS6_GIT_BRANCH=${branch}
    scripts/gen-version.sh
  '';

  preConfigure = ''
    export CACHELINE_WIDTH=${cacheline-width}
  '';

  configureFlags = [
    "--with-symbol-resolution=indirect"
  ];

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
