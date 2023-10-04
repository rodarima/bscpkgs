{
  stdenv
, lib
, cmake
, mpi
, fetchFromGitHub
, useGit ? false
, gitBranch ? "master"
, gitUrl ? "ssh://git@bscpm03.bsc.es/rarias/ovni.git"
, gitCommit ? "d0a47783f20f8b177a48418966dae45454193a6a"
, enableDebug ? false
}:

with lib;

let
  release = rec {
    version = "1.3.0";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "ovni";
      rev = "${version}";
      sha256 = "sha256-4ulohGnbQwAZ/qnm5bmceoMhTuAHlCfLAWEodZ9YMP0=";
    } // { shortRev = "b6903bc4"; };
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
    postPatch = ''
      patchShebangs --build test/
    '';
    buildInputs = [ cmake mpi ];
    cmakeBuildType = if (enableDebug) then "Debug" else "Release";
    cmakeFlags = [ "-DOVNI_GIT_COMMIT=${src.shortRev}" ];
    buildFlags = [ "VERBOSE=1" ];
    preCheck = ''
      export CTEST_OUTPUT_ON_FAILURE=1
    '';
    dontStrip = true;
    doCheck = true;
    checkTarget = "test";
    hardeningDisable = [ "all" ];
  }
