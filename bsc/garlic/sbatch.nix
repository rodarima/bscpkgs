{
  stdenv
, numactl
}:

{
  program
, jobName
, chdirPrefix ? "."
, nixPrefix ? ""
, binary ? "/bin/run"
, ntasks ? null
, ntasksPerNode ? null
, nodes ? null
, exclusive ? true # By default we run in exclusive mode
, qos ? null
, reservation ? null
, time ? null
, output ? "job_%j.out"
, error ? "job_%j.err"
, contiguous ? null
, extra ? null
, acctgFreq ? null
}:

with stdenv.lib;
let

  sbatchOpt = name: value: optionalString (value!=null)
    "#SBATCH --${name}=${value}\n";
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
  programPath = "/${name}";

  installPhase = ''
    mkdir -p $out
    cat > $out/job <<EOF
    #!/bin/sh
    #SBATCH --job-name="${jobName}"
    ''
    + sbatchOpt "ntasks" ntasks
    + sbatchOpt "ntasks-per-node" ntasksPerNode
    + sbatchOpt "nodes" nodes
    + sbatchOpt "chdir" "${chdirPrefix}/$(basename $out)"
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
    exec ${nixPrefix}${program}
    EOF
    
    cat > $out/${name} <<EOF
    #!/bin/sh
    if [ -e "${chdirPrefix}/$(basename $out)" ]; then
      >&2 echo "Execution aborted: '${chdirPrefix}/$(basename $out)' already exists"
      exit 1
    fi
    mkdir -p "${chdirPrefix}/$(basename $out)"
    echo sbatch ${nixPrefix}$out/job
    sbatch ${nixPrefix}$out/job
    EOF
    chmod +x $out/${name}
  '';
}
