{
  stdenv
, slurm
, garlicTools
}:
{
  nextStage
, cpuBind
, nixPrefix
, srunOptions ? ""
}:

with garlicTools;

stdenv.mkDerivation rec {
  name = "srun";
  phases = [ "installPhase" ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh -ex
    exec ${slurm}/bin/srun \
      --mpi=pmi2 \
      --cpu-bind=${cpuBind} \
      ${srunOptions} \
      ${nixPrefix}${stageProgram nextStage}
    EOF
    chmod +x $out
  '';
}
