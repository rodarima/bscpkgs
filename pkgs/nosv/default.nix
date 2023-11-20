{
  stdenv
, lib
, autoreconfHook
, fetchFromGitHub
, pkgconfig
, numactl
, hwloc
, ovni ? null
, useGit ? false
, gitUrl ? "git@gitlab-internal.bsc.es:nos-v/nos-v.git"
, gitBranch ? "master"
, gitCommit ? "0edc81d065f20d3d2f8acf94df1d2640dc430d5e"
}:

with lib;

let
  release = rec {
    version = "1.0.0";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "nos-v";
      rev = "${version}";
      sha256 = "sha256-1Dsxd7OQYxnPvFnpGgCTlG9wbxV8vQpzvSy+cdPD8ro=";
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
    buildInputs = [
      autoreconfHook
      pkgconfig
      numactl
      hwloc
      ovni
    ];
  }
