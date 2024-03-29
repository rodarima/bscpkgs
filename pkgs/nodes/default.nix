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
, ovni
, nosv
, clangOmpss2
, useGit ? false
, gitUrl ? "ssh://git@gitlab-internal.bsc.es/nos-v/nodes.git"
, gitBranch ? "master"
, gitCommit ? "813da5976d06f587747dbb07aa911cfd855eff1a"
}:

with lib;

let
  release = rec {
    version = "1.1";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "nodes";
      rev = "version-${version}";
      hash = "sha256-Cfj3ozVK/sx/eccTjv7wZX8KUMdca0vY0RY0UWSRftg=";
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
    separateDebugInfo = true;

    configureFlags = [
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
      nosv
      ovni
    ];

    passthru = {
      inherit nosv;
    };
  }
