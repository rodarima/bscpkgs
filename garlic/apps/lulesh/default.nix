{
  stdenv
, impi
, mcxx
, icc
, gitBranch ? "garlic/tampi+isend+oss+taskfor"
, tampi ? null
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "lulesh";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm03.bsc.es/garlic/apps/lulesh.git";
    ref = gitBranch;
  };

  dontConfigure = true;

  preBuild = optionalString (tampi != null) "export TAMPI_HOME=${tampi}";

  #TODO: Allow multiple MPI implementations and compilers
  buildInputs = [
    impi
    icc
    mcxx
  ];

  enableParallelBuilding = true;

  #TODO: Can we build an executable named "lulesh" in all branches?
  installPhase = ''
    mkdir -p $out/bin
    find . -name 'lulesh*' -type f -executable -exec cp \{\} $out/bin/${name} \;
  '';
  programPath = "/bin/${name}";

}
