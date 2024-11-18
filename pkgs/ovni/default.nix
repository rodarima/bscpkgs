{
  stdenv
, lib
, cmake
, mpi
, fetchFromGitHub
, useGit ? false
, gitBranch ? "master"
, gitUrl ? "ssh://git@bscpm03.bsc.es/rarias/ovni.git"
, gitCommit ? "a7103f8510d1ec124c3e01ceb47d1e443e98bbf4"
, enableDebug ? false
# Only enable MPI if the build is native (fails on cross-compilation)
, useMpi ? (stdenv.buildPlatform.canExecute stdenv.hostPlatform)
}:

with lib;

let
  release = rec {
    version = "1.11.0";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "ovni";
      rev = "${version}";
      hash = "sha256-DEZUK1dvbPGH5WYkZ2hpP5PShkMxXkHOqMwgYUHHxeM=";
    } // { shortRev = "a7103f8"; };
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
    dontStrip = true;
    separateDebugInfo = true;
    postPatch = ''
      patchShebangs --build test/
    '';
    nativeBuildInputs = [ cmake ];
    buildInputs = lib.optionals (useMpi) [ mpi ];
    cmakeBuildType = if (enableDebug) then "Debug" else "Release";
    cmakeFlags = [
      "-DOVNI_GIT_COMMIT=${src.shortRev}"
    ] ++ lib.optionals (!useMpi) [ "-DUSE_MPI=OFF" ];
    preCheck = ''
      export CTEST_OUTPUT_ON_FAILURE=1
    '';
    doCheck = true;
    checkTarget = "test";
    hardeningDisable = [ "all" ];
  }
