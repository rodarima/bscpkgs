{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
, writeText
, enablePerf ? false
, enableCTF ? false
, enableHWC ? false
, enableExtended ? false
}:

# TODO: Finish HWC first
assert (enableHWC == false);

with stdenv.lib;
with garlicTools;

let
  # Initial variable configuration
  varConf = with bsc; {
    cbs = range2 32 4096;
    rbs = range2 32 4096;
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
    inherit (c) cbs rbs;
    gitBranch = "garlic/tampi+isend+oss+task";
    
    # Repeat the execution of each unit 30 times
    loops = 10;

    # Resources
    qos = "debug";
    ntasksPerNode = 1;
    nodes = 1;
    time = "02:00:00";
    # Assign one socket to each task (only one process)
    cpusPerTask = hw.cpusPerSocket;
    jobName = unitName;
  };

  filterConfigs = c: let
    # Too small sizes lead to huge overheads
    goodSize = (c.cbs * c.rbs >= 1024);
    # When the extended units are not enabled, we only select those in
    # the diagonal.
    extended = if (enableExtended) then true
      else c.cbs == c.rbs;
  in
    goodSize && extended;

  # Compute the array of configurations
  configs = filter (filterConfigs) (stdexp.buildConfigs {
    inherit varConf genConf;
  });

  perf = {nextStage, conf, ...}: stages.perf {
    inherit nextStage;
    perfOptions = "stat -o .garlic/perf.csv -x , " +
      "-e cycles,instructions,cache-references,cache-misses";
  };

  ctf = {nextStage, conf, ...}: let
    # Create the nanos6 configuration file
    nanos6ConfigFile = writeText "nanos6.toml" ''
      version.instrument = "ctf"
      turbo.enabled = false
      instrument.ctf.converter.enabled = false
    '' + optionalString (enableHWC) ''
      hardware_counters.papi.enabled = true
      hardware_counters.papi.counters = [
        "PAPI_TOT_INS", "PAPI_TOT_CYC",
        "PAPI_L1_TCM", "PAPI_L2_TCM", "PAPI_L3_TCM"
      ]
    '';

  in stages.exec {
    inherit nextStage;

    # And use it
    env = ''
      export NANOS6_CONFIG=${nanos6ConfigFile}
    '';

    # FIXME: We should run a hook *after* srun has ended, so we can
    # execute it in one process only (not in N ranks). This hack works
    # with one process only. Or be able to compute the name of the trace
    # directory so we can begin the conversion in parallel
    post = assert (conf.nodes * conf.ntasksPerNode == 1); ''
      tracedir=$(ls -d trace_* | head -1)
      echo "using tracedir=$tracedir"

      offset=$(grep 'offset =' $tracedir/ctf/ust/uid/1000/64-bit/metadata | \
        grep -o '[0-9]*')
      echo "offset = $offset"

      start_time=$(awk '/^start_time / {print $2}' stdout.log)
      end_time=$(awk '/^end_time / {print $2}' stdout.log)

      begin=$(awk "BEGIN{print $start_time*1e9 - $offset}")
      end=$(awk "BEGIN{print $end_time*1e9 - $offset}")

      echo "only events between $begin and $end"

      ${bsc.cn6}/bin/cn6 -s $tracedir

      ${bsc.cn6}/bin/cut $begin $end < $tracedir/prv/trace.prv |\
        ${bsc.cn6}/bin/hcut 1 ${toString conf.cpusPerTask} \
        > $tracedir/prv/trace-cut.prv

      ${bsc.cn6}/bin/dur 6400025 0 < $tracedir/prv/trace-cut.prv |\
        awk '{s+=$1} END {print s}' >> .garlic/time_mode_dead.csv &

      ${bsc.cn6}/bin/dur 6400025 1 < $tracedir/prv/trace-cut.prv |\
        awk '{s+=$1} END {print s}' >> .garlic/time_mode_runtime.csv &

      ${bsc.cn6}/bin/dur 6400025 3 < $tracedir/prv/trace-cut.prv |\
        awk '{s+=$1} END {print s}' >> .garlic/time_mode_task.csv &

      wait

      # Remove the traces at the end, as they are huge
      rm -rf $tracedir
      '';
      # TODO: To enable HWC we need to first add a taskwait before the
      # first get_time() measurement, otherwise we get the HWC of the
      # main task, which will be huge.
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
