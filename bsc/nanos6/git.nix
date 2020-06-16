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
  version = "2.3.2";
  branch = "master";
  cacheline-width = "64";

  src = builtins.fetchGit {
    url = "git@bscpm02.bsc.es:rarias/nanos6";
    rev = "61ba5d39d7f9c99ca41b74fff34e0284bf039881";
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