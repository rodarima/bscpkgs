{
  stdenv
, lib
, autoreconfHook
, fetchFromGitHub
, pkg-config
, numactl
, hwloc
, cacheline ? 64 # bits
, ovni ? null
, useGit ? false
, gitUrl ? "git@gitlab-internal.bsc.es:nos-v/nos-v.git"
, gitBranch ? "master"
, gitCommit ? "9f47063873c3aa9d6a47482a82c5000a8c813dd8"
}:

with lib;

let
  release = rec {
    version = "3.2.0";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "nos-v";
      rev = "${version}";
      hash = "sha256-yaz92426EM8trdkBJlISmAoG9KJCDTvoAW/HKrasvOw=";
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
    configureFlags = [
      "--with-ovni=${ovni}"
      "CACHELINE_WIDTH=${toString cacheline}"
    ];
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
