{
  stdenv
, slurm
, garlicTools
}:
{
  nextStage
, cpuBind
, nixPrefix
, preSrun ? ""
, postSrun ? ""
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

    ${preSrun}

    ${slurm}/bin/srun \
      --mpi=pmi2 \
      --cpu-bind=${cpuBind} \
      --output=${output} \
      --error=${error} \
      ${srunOptions} \
      ${nixPrefix}${stageProgram nextStage}

    ${postSrun}
    EOF

    chmod +x $out
  '';
}
