{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, enablePerf ? false
, enableCTF ? false
}:

with stdenv.lib;
with garlicTools;

let
  # Initial variable configuration
  varConf = with bsc; {
    #cbs = range2 32 4096;
    #rbs = range2 32 4096;
    cbs = [ 64 256 1024 4096 ];
    rbs = [ 32 128 512 1024 ];
    #cbs = [ 4096 ];
    #rbs = [ 32 ];
  };

  machineConfig = targetMachine.config;

  # Generate the complete configuration for each unit
  genConf = with bsc; c: targetMachine.config // rec {
    expName = "heat";
    unitName = expName +
      ".cbs-${toString cbs}" +
      ".rbs-${toString rbs}";

    inherit (machineConfig) hw;

    # heat options
    timesteps = 10;
    cols = 1024 * 16; # Columns
    rows = 1024 * 16; # Rows
    cbs = c.cbs;
    rbs = c.rbs;
    gitBranch = "garlic/tampi+isend+oss+task";
    
    # Repeat the execution of each unit 30 times
    loops = 1;

    # Resources
    qos = "debug";
    ntasksPerNode = 1;
    nodes = 1;
    time = "02:00:00";
    # Assign one socket to each task (only one process)
    cpusPerTask = hw.cpusPerSocket;
    jobName = unitName;
  };

  # Compute the array of configurations
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  perf = {nextStage, conf, ...}: stages.perf {
    inherit nextStage;
    perfOptions = "stat -o .garlic/perf.csv -x , " +
      "-e cycles,instructions,cache-references,cache-misses";
  };

  ctf = {nextStage, conf, ...}: with conf; stages.exec {
    inherit nextStage;
    env = ''
      export NANOS6_CONFIG_OVERRIDE="version.instrument=ctf,\
        instrument.ctf.converter.enabled=false"
    '';
    # Only one process converts the trace, otherwise use:
    #  if [ $SLURM_PROCID == 0 ]; then
    #    ...
    #  fi
    post = ''
      if [ $SLURM_PROCID == 0 ]; then
        sleep 2
        for tracedir in trace_*; do
          offset=$(grep 'offset =' $tracedir/ctf/ust/uid/1000/64-bit/metadata | \
            grep -o '[0-9]*')
          echo "offset = $offset"

          start_time=$(awk '/^start_time / {print $2}' stdout.log)
          end_time=$(awk '/^end_time / {print $2}' stdout.log)

          begin=$(awk "BEGIN{print $start_time*1e9 - $offset}")
          end=$(awk "BEGIN{print $end_time*1e9 - $offset}")

          echo "only events between $begin and $end"

          ${bsc.cn6}/bin/cn6 -s $tracedir

          awk -F: "NR==1 {print} \$6 >= $begin && \$6 <= $end" $tracedir/prv/trace.prv |\
            ${bsc.cn6}/bin/dur 6400025 0 |\
            awk '{s+=$1} END {print s}' >> .garlic/time_mode_dead.csv &

          awk -F: "NR==1 {print} \$6 >= $begin && \$6 <= $end" $tracedir/prv/trace.prv |\
            ${bsc.cn6}/bin/dur 6400025 1 |\
            awk '{s+=$1} END {print s}' >> .garlic/time_mode_runtime.csv &

          awk -F: "NR==1 {print} \$6 >= $begin && \$6 <= $end" $tracedir/prv/trace.prv |\
            ${bsc.cn6}/bin/dur 6400025 3 |\
            awk '{s+=$1} END {print s}' >> .garlic/time_mode_task.csv &

          wait

          # Remove the traces at the end, as they are huge
          rm -rf $tracedir
          #cp -a $tracedir .garlic/
        done
      fi
    '';
  };

  exec = {nextStage, conf, ...}: stages.exec {
    inherit nextStage;
    argv = [
      "--rows" conf.rows
      "--cols" conf.cols
      "--rbs" conf.rbs
      "--cbs" conf.cbs
      "--timesteps" conf.timesteps
    ];

    # The next stage is the program
    env = ''
      ln -sf ${nextStage}/etc/heat.conf heat.conf || true
    '';
  };

  program = {nextStage, conf, ...}: bsc.garlic.apps.heat.override {
    inherit (conf) gitBranch;
  };

  pipeline = stdexp.stdPipeline ++
    (optional enablePerf perf) ++
    (optional enableCTF ctf) ++
    [ exec program ];

in
 
  stdexp.genExperiment { inherit configs pipeline; }
