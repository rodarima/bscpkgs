{
  stdenv
, lib
, babeltrace2
, pkg-config
, uthash
, enableTest ? false
, mpi ? null
, clangOmpss2 ? null
, tampi ? null
}:

with lib;

assert (enableTest -> (mpi != null));
assert (enableTest -> (clangOmpss2 != null));
assert (enableTest -> (tampi != null));

stdenv.mkDerivation rec {
  pname = "cn6";
  version = "${src.shortRev}";

  buildInputs = [
    babeltrace2
    pkg-config
    uthash
    mpi
  ] ++ optionals (enableTest) [ mpi clangOmpss2 tampi ];

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/rarias/cn6.git";
    ref = "master";
    rev = "c72c3b66b720c2a33950f536fc819051c8f20a69";
  };

  makeFlags = [ "PREFIX=$(out)" ];

  postBuild = optionalString (enableTest) ''
    (
      cd test
      make timediff timediff_mpi
    )
  '';

  postInstall = optionalString (enableTest) ''
    (
      cd test
      cp timediff timediff_mpi sync-err.sh $out/bin/
    )
  '';
}
