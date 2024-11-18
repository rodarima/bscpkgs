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
, gitCommit ? "cfd361bd1dd30c96da405e6bbaa7e78f5f93dfda"
}:

with lib;

let
  release = rec {
    version = "3.1.0";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "nos-v";
      rev = "${version}";
      hash = "sha256-Pkre+ZZsREDxJLCoIoPN1HQDuUa2H1IQyKB3omg6qaU=";
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
