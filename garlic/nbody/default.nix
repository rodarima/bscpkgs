{
  stdenv
, cc
, mpi ? null
, tampi ? null
, mcxx ? null
, cflags ? null
, gitBranch
, gitURL ? "ssh://git@bscpm02.bsc.es/garlic/apps/nbody.git"
, blocksize ? 2048
}:

assert !(tampi != null && mcxx == null);

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "nbody";

  #src = /home/Computational/rarias/bscpkgs/manual/nbody;

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

  postPatch = ""

  # This should be fixed in the Makefile as well.
  + ''sed -i 's/libtampi.a/libtampi-c.a/g' Makefile
  ''
  # Dirty HACK until the nbody issue at:
  # https://pm.bsc.es/gitlab/garlic/apps/nbody/-/issues/1
  # is properly fixed.
  +
    (if (mpi.pname or "unknown") == "openmpi" then
      ''sed -i 's/-lstdc++/-lstdc++ -lmpi_cxx/g' Makefile
      ''
    else
      ""
    );

  makeFlags = [
    "CC=${cc.cc.CC}"
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
