{
  stdenv
}:
{ app , nixPrefix ? "" }:

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
    exec srun --mpi=pmi2 ${nixPrefix}${app}/bin/run
    EOF
    chmod +x $out/bin/run
  '';
}
