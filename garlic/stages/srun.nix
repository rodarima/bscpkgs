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

    >&2 echo srun exit code: $?

    # Ensure that none failed, as srun fails to capture errors
    # after MPI_Finalize
    for i in $(seq 0 $(($SLURM_NTASKS - 1))); do
      if [ ! -e .srun.rc.$i ]; then
        >&2 echo "missing exit code for rank $i, aborting"
        exit 1
      fi
      if ! grep -q '^0$' .srun.rc.$i; then
        >&2 echo "non-zero exit for rank $i, aborting"
        exit 1
      fi
    done

    ${postSrun}
    EOF

    chmod +x $out
  '';
}
