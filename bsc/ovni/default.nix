{
  stdenv
, lib
, cmake
, mpi
, fetchFromGitHub
, useGit ? false
, gitBranch ? "master"
, gitURL ? "ssh://git@bscpm03.bsc.es/rarias/ovni.git"
, gitCommit ? "d0a47783f20f8b177a48418966dae45454193a6a"
, enableDebug ? false
}:

with lib;

let
  release = rec {
    version = "1.2.0";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "ovni";
      rev = "${version}";
      sha256 = "sha256-J6eC62RT/0CHN7IXJuIw1c9GBkjvVEyh0HjIF7uG0FM=";
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
    pname = "ovni";
    inherit (source) src version;
    buildInputs = [ cmake mpi ];
    cmakeBuildType = if (enableDebug) then "Debug" else "Release";
    dontStrip = true;
  }
