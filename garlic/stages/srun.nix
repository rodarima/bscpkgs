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
, output ? "stdout.log"
, error ? "stderr.log"
}:

with garlicTools;

stdenv.mkDerivation rec {
  name = "srun";
  phases = [ "installPhase" ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  installPhase = ''
    cat > $out <<'EOF'
    #!/bin/sh -e
    exec ${slurm}/bin/srun \
      --mpi=pmi2 \
      --cpu-bind=${cpuBind} \
      --output=${output} \
      --error=${error} \
      ${srunOptions} \
      ${nixPrefix}${stageProgram nextStage}
    EOF
    chmod +x $out
  '';
}
