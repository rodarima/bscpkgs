{
  stdenv
, lib
, automake
, autoconf
, libtool
, fetchFromGitHub
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
, useGit ? false
, gitUrl ? "ssh://git@gitlab-internal.bsc.es/nos-v/nodes.git"
, gitBranch ? "master"
, gitCommit ? "c1094418a0a4dbfe78fa38b3f44741bd36d56e51"
}:

with lib;

let
  release = rec {
    version = "1.0";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "nodes";
      rev = "version-${version}";
      sha256 = "sha256-UqqvbAqF512qsHsEE24WNSxnV1wCGAXuzc7FkzQxu10=";
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
  stdenv.mkDerivation rec {
    pname = "nodes";
    inherit (source) src version;

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
