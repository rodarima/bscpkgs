{
  stdenv
, numactl
, slurm
, garlicTools
}:

{
  nextStage
, jobName
, chdir ? "."
, nixPrefix ? ""
, binary ? "/bin/run"
, ntasks ? null
, ntasksPerNode ? null
, ntasksPerSocket ? null
, nodes ? null
, exclusive ? true # By default we run in exclusive mode
, qos ? null
, reservation ? null
, time ? null
, output ? "stdout.log"
, error ? "stderr.log"
, contiguous ? null
, extra ? null
, acctgFreq ? null
}:

with stdenv.lib;
with garlicTools;

let

  sbatchOpt = name: value: optionalString (value!=null)
    "#SBATCH --${name}=${toString value}\n";
  sbatchEnable = name: value: optionalString (value!=null)
    "#SBATCH --${name}\n";

in

stdenv.mkDerivation rec {
  name = "sbatch";
  preferLocalBuild = true;

  phases = [ "installPhase" ];

  #SBATCH --tasks-per-node=48
  #SBATCH --ntasks-per-socket=24
  #SBATCH --cpus-per-task=1
  dontBuild = true;
  dontPatchShebangs = true;
  programPath = "/run";

  installPhase = ''
    mkdir -p $out
    cat > $out/job <<EOF
    #!/bin/sh -e
    #SBATCH --job-name="${jobName}"
    ''
    + sbatchOpt "ntasks" ntasks
    + sbatchOpt "ntasks-per-node" ntasksPerNode
    + sbatchOpt "ntasks-per-socket" ntasksPerSocket
    + sbatchOpt "nodes" nodes
    + sbatchOpt "chdir" chdir
    + sbatchOpt "output" output
    + sbatchOpt "error" error
    + sbatchEnable "exclusive" exclusive
    + sbatchOpt "time" time
    + sbatchOpt "qos" qos
    + sbatchOpt "reservation" reservation
    + sbatchOpt "acctg-freq" acctgFreq
    + optionalString (extra!=null) extra
    +
    ''
    exec ${nixPrefix}${stageProgram nextStage}
    EOF
    
    cat > $out/run <<EOF
    #!/bin/sh -e
    ${slurm}/bin/sbatch ${nixPrefix}$out/job
    EOF
    chmod +x $out/run
  '';
}
