{
  stdenv
, numactl
}:

{
  app
, prefix ? ""
, argv ? ""
, binary ? "/bin/run"
, ntasks ? null
, exclusive ? true # By default we run in exclusive mode
, chdir ? "."
, qos ? null
, time ? null
, output ? "job_%j.out"
, error ? "job_%j.err"
, contiguous ? null
, extra ? null
}:

with stdenv.lib;
let

  sbatchOpt = name: value: optionalString (value!=null)
    "#SBATCH --${name}=${value}\n";
  sbatchEnable = name: value: optionalString (value!=null)
    "#SBATCH --${name}\n";

in

stdenv.mkDerivation rec {
  name = "${app.name}-job";
  preferLocalBuild = true;

  src = ./.;

  buildInputs = [ app ];

  #SBATCH --tasks-per-node=48
  #SBATCH --ntasks-per-socket=24
  #SBATCH --cpus-per-task=1
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cat > $out/job <<EOF
    #!/bin/bash
    #SBATCH --job-name="${name}"
    ''
    + sbatchOpt "ntasks" ntasks
    + sbatchOpt "chdir" chdir
    + sbatchOpt "output" output
    + sbatchOpt "error" error
    + sbatchEnable "exclusive" exclusive
    + sbatchOpt "time" time
    + sbatchOpt "qos" qos
    + optionalString (extra!=null) extra
    +
    ''
    srun ${prefix}${app}${binary} ${argv}
    EOF
  '';
}
