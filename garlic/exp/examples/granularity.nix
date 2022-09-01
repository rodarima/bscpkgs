# This file defines an experiment. It is designed as a function that takes
# several parameters and returns a derivation. This derivation, when built will
# create several scripts that can be executed and launch the experiment.

# These are the inputs to this function: an attribute set which must contain the
# following keys:
{
  stdenv
, lib
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
}:

# We import in the scope the content of the `lib` attribute, which
# contain useful functions like `toString`, which will be used later. This is
# handy to avoid writting `lib.tostring`.

with lib;

# We also have some functions specific to the garlic benchmark which we import
# as well. Take a look at the garlic/tools.nix file for more details.
with garlicTools;

# The `let` keyword allows us to define some local variables which will be used
# later. It works as the local variable concept in the C language.
let

  # Initial variable configuration: every attribute in this set contains lists
  # of options which will be used to compute the configuration of the units. The
  # cartesian product of all the values will be computed.
  varConf = {
    # In this case we will vary the columns and rows of the blocksize. This
    # configuration will create 3 x 2 = 6 units.
    cbs = [ 256 1024 4096 ];
    rbs = [ 512 1024 ];
  };

  # Generate the complete configuration for each unit: genConf is a function
  # that accepts the argument `c` and returns a attribute set. The attribute set
  # is formed by joining the configuration of the machine (which includes
  # details like the number of nodes or the architecture) and the configuration
  # that we define for our units.
  #
  # Notice the use of the `rec` keyword, which allows us to access the elements
  # of the set while is being defined.
  genConf = c: targetMachine.config // rec {

    # These attributes are user defined, and thus the user will need to handle
    # them manually. They are not read by the standard pipeline:

    # Here we load the `hw` attribute from the machine configuration, so we can
    # access it, for example, the number of CPUs per socket as hw.cpusPerSocket.
    hw = targetMachine.config.hw;

    # These options will be used by the heat app, be we write them here so they
    # are stored in the unit configuration.
    timesteps = 10;
    cols = 1024 * 16; # Columns
    rows = 1024 * 16; # Rows

    # The blocksize is set to the values passed in the `c` parameter, which will
    # be set to one of all the configurations of the cartesian product. for
    # example: cbs = 256 and rbs = 512.
    # We can also write `inherit (c) cbs rbs`, as is a shorthand notation.
    cbs = c.cbs;
    rbs = c.rbs;

    # The git branch is specified here as well, as will be used when we specify
    # the heat app
    gitBranch = "garlic/tampi+isend+oss+task";

    # -------------------------------------------------------------------------

    # These attributes are part of the standard pipeline, and are required for
    # each experiment. They are automatically recognized by the standard
    # execution pipeline.

    # The experiment name:
    expName = "example-granularity-heat";

    # The experimental unit name. It will be used to create a symlink in the
    # index (at /gpfs/projects/bsc15/garlic/$USER/index/) so you can easily find
    # the unit. Notice that the symlink is overwritten each time you run a unit
    # with the same same.
    #
    # We use the toString function to convert the numeric value of cbs and rbs
    # to a string like: "example-granularity-heat.cbs-256.rbs-512"
    unitName = expName +
      ".cbs-${toString cbs}" +
      ".rbs-${toString rbs}";
    
    # Repeat the execution of each unit a few times: this option is
    # automatically taken by the experiment, which will repeat the execution of
    # the program that many times. It is recommended to run the app at least 30
    # times, but we only used 10 here for demostration purposes (as it will be
    # faster to run)
    loops = 10;

    # Resources: here we configure the resources in the machine. The queue to be
    # used is `debug` as is the fastest for small jobs.
    qos = "debug";

    # Then the number of MPI processes or tasks per node:
    ntasksPerNode = 1;

    # And the number of nodes:
    nodes = 1;

    # We use all the CPUs available in one socket to each MPI process or task.
    # Notice that the number of CPUs per socket is not specified directly. but
    # loaded from the configuration of the machine that will be used to run our
    # experiment. The affinity mask is set accordingly.
    cpusPerTask = hw.cpusPerSocket;

    # The time will limit the execution of the program in case of a deadlock
    time = "02:00:00";

    # The job name will appear in the `squeue` and helps to identify what is
    # running. Currently is set to the name of the unit.
    jobName = unitName;
  };

  # Using the `varConf` and our function `genConf` we compute a list of the
  # complete configuration of every unit.
  configs = stdexp.buildConfigs {
    inherit varConf genConf;
  };

  # Now that we have the list of configs, we need to write how that information
  # is used to run our program. In our case we will use some params such as the
  # number of rows and columns of the input problem or the blocksize as argv
  # values.

  # The exec stage is used to run a program with some arguments.
  exec = {nextStage, conf, ...}: stages.exec {
    # All stages require the nextStage attribute, which is passed as parameter.
    inherit nextStage;

    # Then, we fill the argv array with the elements that will be used when
    # running our program. Notice that we load the attributes from the
    # configuration which is passed as argument as well.
    argv = [
      "--rows" conf.rows
      "--cols" conf.cols
      "--rbs" conf.rbs
      "--cbs" conf.cbs
      "--timesteps" conf.timesteps
    ];

    # This program requires a file called `head.conf` in the current directory.
    # To do it, we run this small script in the `pre` hook, which simple runs
    # some commands before running the program. Notice that this command is
    # executed in every MPI task.
    pre = ''
      ln -sf ${nextStage}/etc/heat.conf heat.conf || true
    '';
  };

  # The program stage is only used to specify which program we should run.
  # We use this stage to specify build-time parameters such as the gitBranch,
  # which will be used to fetch the source code. We use the `override` function
  # of the `bsc.garlic.apps.heat` derivation to change the input paramenters.
  program = {nextStage, conf, ...}: bsc.garlic.apps.heat.override {
    inherit (conf) gitBranch;
  };

  # Other stages may be defined here, in case that we want to do something
  # additional, like running the program under `perf stats` or set some
  # envionment variables.

  # Once all the stages are defined, we build the pipeline array. The
  # `stdexp.stdPipeline` contains the standard pipeline stages, so we don't need
  # to specify them. We only specify how we run our program, and what program
  # exactly, by adding our `exec` and `program` stages:
  pipeline = stdexp.stdPipeline ++ [ exec program ];

# Then, we use the `configs` and the `pipeline` just defined inside the `in`
# part, to build the complete experiment:
in

  # The `stdexp.genExperiment` function generates an experiment by calling every
  # stage of the pipeline with the different configs, and thus creating
  # different units. The result is the top level derivation which is the
  # `trebuchet`, which is the script that, when executed, launches the complete
  # experiment.
  stdexp.genExperiment { inherit configs pipeline; }
