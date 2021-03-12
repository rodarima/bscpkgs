{
  stdenv
, mpi
, tampi
, mcxx
, gitBranch ? "master"
}:

stdenv.mkDerivation rec {
  name = "heat";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/garlic/apps/heat.git";
    ref = gitBranch;
  };

  patches = [ ./print-times.patch ];

  buildInputs = [
    mpi
    mcxx
    tampi
  ];

  programPath = "/bin/${name}";

  installPhase = ''
    mkdir -p $out/bin
    cp ${name} $out/bin/

    mkdir -p $out/etc
    cp heat.conf $out/etc/
  '';

}
