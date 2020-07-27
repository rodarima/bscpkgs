{
  stdenv
, branch ? null
, srcPath ? null
}:

#assert if srcPath == null then branch != null else true;

stdenv.mkDerivation rec {
  name = "dummy";

  src = (if srcPath != null then srcPath else
    builtins.fetchGit {
      url = "ssh://git@bscpm02.bsc.es/rarias/dummy.git";
      ref = "${branch}";
    }
  );
}
