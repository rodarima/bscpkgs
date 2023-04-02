{
  stdenv
, slurm
}:

stdenv.mkDerivation rec {
  name = "pmi2-${version}";

  inherit (slurm) src version prePatch nativeBuildInputs buildInputs
    configureFlags preConfigure;

  # Only build the pmi2 library
  preBuild = ''cd contribs/pmi2'';

  # Include also the pmi.h header
  postInstall = ''
    mkdir -p $out/include
    cp ../../slurm/pmi.h $out/include
  '';

  enableParallelBuilding = true;
}
