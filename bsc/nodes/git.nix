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
, boost
, autoreconfHook
, jemalloc
, enableOvni ? false
, ovni ? null
, nosv
, gitUrl ? "ssh://git@gitlab-internal.bsc.es/nos-v/nodes.git"
, gitBranch ? "master"
}:

with lib;

stdenv.mkDerivation rec {
  pname = "nodes";
  version = "${src.shortRev}";

  src = builtins.fetchGit {
    url = gitUrl;
    ref = gitBranch;
  };

  enableParallelBuilding = true;
  dontStrip = true;

  configureFlags = [
    "--with-jemalloc=${jemalloc}"
    "--with-nosv=${nosv}"
  ] ++
    (optional enableOvni "--with-ovni=${ovni}");

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
    jemalloc
    nosv
  ] ++
    (optional enableOvni ovni);
}
