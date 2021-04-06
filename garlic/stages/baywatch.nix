{
  stdenv
, garlicTools
}:
{
  nextStage
}:

with garlicTools;

stdenv.mkDerivation rec {
  name = "baywatch";
  phases = [ "installPhase" ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  installPhase = ''
    cat > $out <<'EOF'
    #!/bin/sh -e

    ${stageProgram nextStage}
    echo $? >> .srun.rc.$SLURM_PROCID

    EOF
    chmod +x $out
  '';
}
