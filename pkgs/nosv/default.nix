{
  stdenv
, lib
, autoreconfHook
, fetchFromGitHub
, pkg-config
, numactl
, hwloc
, ovni ? null
, useGit ? false
, gitUrl ? "git@gitlab-internal.bsc.es:nos-v/nos-v.git"
, gitBranch ? "master"
, gitCommit ? "f696951f62cac018bd9fd15e2fb9f34e96b185b5"
}:

with lib;

let
  release = rec {
    version = "2.1.1";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "nos-v";
      rev = "${version}";
      hash = "sha256-G80vaHep72iovnlIgqqjaQOYYtn83UJG7XrXnI/WO70=";
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
    pname = "nosv";
    inherit (source) src version;
    hardeningDisable = [ "all" ];
    dontStrip = true;
    separateDebugInfo = true;
    configureFlags = [ "--with-ovni=${ovni}" ];
    nativeBuildInputs = [
      autoreconfHook
      pkg-config
    ];
    buildInputs = [
      numactl
      hwloc
      ovni
    ];
  }
