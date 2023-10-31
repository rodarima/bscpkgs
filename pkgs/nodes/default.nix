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
, ovni
, nosv
, clangOmpss2
, useGit ? false
, gitUrl ? "ssh://git@gitlab-internal.bsc.es/nos-v/nodes.git"
, gitBranch ? "master"
, gitCommit ? "c1094418a0a4dbfe78fa38b3f44741bd36d56e51"
}:

with lib;

let
  release = rec {
    version = "1.0.1";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "nodes";
      rev = "version-${version}";
      sha256 = "sha256-+gnFSjScxq+AB0FJxqxk388chayyDiQ+wBpCMKnX6m4=";
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
      "--with-ovni=${ovni}"
    ] ++ lib.optionals doCheck [
      "--with-nodes-clang=${clangOmpss2}"
    ];

    doCheck = false;
    nativeCheckInputs = [
      clangOmpss2
    ];

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
      ovni
    ];
  }
