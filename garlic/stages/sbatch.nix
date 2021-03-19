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
, cpusPerTask ? null
, nodes ? null
, exclusive ? true # By default we run in exclusive mode
, qos ? null
, reservation ? null
, time ? null
, output ? "stdout.log"
, error ? "stderr.log"
, extra ? null
, acctgFreq ? null
}:

with stdenv.lib;
with garlicTools;

# sbatch fails silently if we pass garbage, so we assert the types here to avoid
# sending `nodes = [ 1 2 ]` by mistake.
assert (jobName != null) -> isString jobName;
assert (chdir != null) -> isString chdir;
assert (nixPrefix != null) -> isString nixPrefix;
assert (ntasks != null) -> isInt ntasks;
assert (ntasksPerNode != null) -> isInt ntasksPerNode;
assert (ntasksPerSocket != null) -> isInt ntasksPerSocket;
assert (cpusPerTask != null) -> isInt cpusPerTask;
assert (nodes != null) -> isInt nodes;
assert (exclusive != null) -> isBool exclusive;
assert (qos != null) -> isString qos;
assert (reservation != null) -> isString reservation;
assert (time != null) -> isString time;
assert (output != null) -> isString output;
assert (error != null) -> isString error;
assert (extra != null) -> isString extra;

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
    + sbatchOpt "cpus-per-task" cpusPerTask
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
