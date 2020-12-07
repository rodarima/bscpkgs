{
  stdenv
, cc
, mpi ? null
, tampi ? null
, mcxx ? null
, cflags ? null
, gitBranch
, gitURL ? "ssh://git@bscpm03.bsc.es/garlic/apps/nbody.git"
, blocksize ? 2048
}:

assert !(tampi != null && mcxx == null);

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "nbody";

  #src = ~/nbody;

  src = builtins.fetchGit {
    url = "${gitURL}";
    ref = "${gitBranch}";
  };
  programPath = "/bin/nbody";

  buildInputs = [
    cc
  ]
  ++ optional (mpi != null) mpi
  ++ optional (tampi != null) tampi
  ++ optional (mcxx != null) mcxx;

  preBuild = (if cflags != null then ''
    makeFlagsArray+=(CFLAGS="${cflags}")
  '' else "");

  makeFlags = [
    "CC=${cc.CC}"
    "BS=${toString blocksize}"
  ]
  ++ optional (tampi != null) "TAMPI_HOME=${tampi}";

  dontPatchShebangs = true;

  installPhase = ''
    echo ${tampi}
    mkdir -p $out/bin
    cp nbody* $out/bin/${name}
  '';

}
