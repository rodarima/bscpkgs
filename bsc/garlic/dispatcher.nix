{
  stdenv
, jobs
}:

stdenv.mkDerivation {
  name = "slurm-dispatcher";
  preferLocalBuild = true;

  buildInputs = [] ++ jobs;
  jobs = jobs;
  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/jobs
    for j in $jobs; do
      ln -s $j/job $out/jobs/$(basename $j)
    done

    mkdir -p $out/bin
    cat > $out/bin/execute-all-jobs <<EOF
    #!/bin/sh

    for j in $out/jobs/*; do
      echo "sbatch \$j"
      sbatch \$j
    done
    EOF

    chmod +x $out/bin/execute-all-jobs
  '';
}
