{
  stdenv
, lib
, autoreconfHook
, pkgconfig
, numactl
, hwloc
, ovni ? null
, enableOvni ? false
, gitURL ? "git@gitlab-internal.bsc.es:nos-v/nos-v.git"
, gitBranch ? "master"
, gitCommit ? null
}:

with lib;

stdenv.mkDerivation rec {
  pname = "nosv";
  version = "${src.shortRev}";

  inherit gitURL gitCommit gitBranch;
  
  src = builtins.fetchGit ({
      url = gitURL;
      ref = gitBranch;
    } // (optionalAttrs (gitCommit != null) { rev = gitCommit; })
  );

  hardeningDisable = [ "all" ];
  dontStrip = true;

  configureFlags = optional (enableOvni) "--with-ovni=${ovni}";
  
  buildInputs = [
    autoreconfHook
    pkgconfig
    numactl
    hwloc
  ] ++ (optional (enableOvni) ovni);
}
