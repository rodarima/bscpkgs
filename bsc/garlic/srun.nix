{
  stdenv
}:
{
  app
, nixPrefix ? ""
, srunOptions ? ""
}:

stdenv.mkDerivation rec {
  name = "${app.name}-srun";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  buildInputs = [ app ];
  dontPatchShebangs = true;
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!/bin/sh
    exec srun --mpi=pmi2 ${srunOptions} ${nixPrefix}${app}/bin/run
    EOF
    chmod +x $out/bin/run
  '';
}
