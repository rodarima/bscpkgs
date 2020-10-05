{
  stdenv
, slurm
}:
{
  program
, nixPrefix ? ""
, srunOptions ? ""
}:

stdenv.mkDerivation rec {
  name = "srun";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  dontPatchShebangs = true;
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh -ex
    exec ${slurm}/bin/srun --mpi=pmi2 ${srunOptions} \
      ${nixPrefix}${program}
    EOF
    chmod +x $out
  '';
}
