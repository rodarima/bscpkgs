{
  stdenv
, lib
, cmake
, mpi
, fetchFromGitHub
, useGit ? false
, gitBranch ? "master"
, gitUrl ? "ssh://git@bscpm03.bsc.es/rarias/ovni.git"
, gitCommit ? "7a33deffb7aaae70527125d48428f22169c9d39e"
, enableDebug ? false
}:

with lib;

let
  release = rec {
    version = "1.4.1";
    src = fetchFromGitHub {
      owner = "bsc-pm";
      repo = "ovni";
      rev = "${version}";
      hash = "sha256-/vv7Yy6dzoxuHjMc0h/vFFwWzysPLXFZIN2rbLT/SC8=";
    } // { shortRev = "7a33def"; };
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
    buildInputs = [ cmake mpi ];
    cmakeBuildType = if (enableDebug) then "Debug" else "Release";
    cmakeFlags = [ "-DOVNI_GIT_COMMIT=${src.shortRev}" ];
    preCheck = ''
      export CTEST_OUTPUT_ON_FAILURE=1
    '';
    doCheck = true;
    checkTarget = "test";
    hardeningDisable = [ "all" ];
  }
