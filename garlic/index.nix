{
  super
, self
, bsc
, callPackage
}:

{
  develop = let
    commonPackages = with self; [
      coreutils htop procps-ng vim which strace
      tmux gdb kakoune universal-ctags bashInteractive
      glibcLocales ncurses git screen curl
      # Add more nixpkgs packages here...
    ];
    bscPackages = with bsc; [
      slurm clangOmpss2 icc mcxx perf tampi impi
      # Add more bsc packages here...
    ];
    packages = commonPackages ++ bscPackages;
  in
    bsc.garlic.stages.exec rec {
      nextStage = bsc.garlic.stages.isolate {
        nextStage = bsc.garlic.unsafeDevelop.override {
          extraInputs = packages;
        };
        nixPrefix = bsc.garlic.targetMachine.config.nixPrefix;
        extraMounts = [ "/tmp:$TMPDIR" ];
      };
      nixPrefix = bsc.garlic.targetMachine.config.nixPrefix;
      # This hack uploads all dependencies to MN4
      pre = let
        nixPrefix = bsc.garlic.targetMachine.config.nixPrefix;
        stageProgram = bsc.garlicTools.stageProgram;
      in
      ''
        # Hack to upload this to MN4: @upload-to-mn@

        # Create a link to the develop script
        ln -fs ${nixPrefix}${stageProgram nextStage} .nix-develop
      '';
      post = "\n";
  };

  unsafeDevelop = callPackage ./develop/default.nix { };

  # Configuration for the machines
  machines = callPackage ./machines.nix { };

  report = callPackage ./report.nix {
    fig = bsc.garlic.fig;
  };

  sedReport = callPackage ./sedReport.nix {
    fig = bsc.garlic.fig;
  };

  bundleReport = callPackage ./bundleReport.nix {
    fig = bsc.garlic.fig;
  };

  reportTar = callPackage ./reportTar.nix {
    fig = bsc.garlic.fig;
  };

  # Use the configuration for the following target machine
  targetMachine = bsc.garlic.machines.mn4;

  # Load some helper functions to generate app variants

  stdexp = callPackage ./stdexp.nix {
    inherit (bsc.garlic) targetMachine stages pp;
  };

  # Execution stages
  stages = {
    sbatch     = callPackage ./stages/sbatch.nix { };
    srun       = callPackage ./stages/srun.nix { };
    control    = callPackage ./stages/control.nix { };
    exec       = callPackage ./stages/exec.nix { };
    script     = callPackage ./stages/script.nix { };
    extrae     = callPackage ./stages/extrae.nix { };
    valgrind   = callPackage ./stages/valgrind.nix { };
    perf       = callPackage ./stages/perf.nix { };
    isolate    = callPackage ./stages/isolate { };
    runexp     = callPackage ./stages/runexp { };
    trebuchet  = callPackage ./stages/trebuchet.nix { };
    strace     = callPackage ./stages/strace.nix { };
    unit       = callPackage ./stages/unit.nix { };
    experiment = callPackage ./stages/experiment.nix { };
  };

  # Tests (move to bsc ?)
  mpptest = callPackage ./mpptest { };

  ppong = callPackage ./ppong {
    mpi = bsc.mpi;
  };

  hist = callPackage ./pp/hist { };

  tool = callPackage ./sh/default.nix {
    sshHost = "mn1";
  };

  # Post processing tools
  pp = with bsc.garlicTools; rec {
    store = callPackage ./pp/store.nix { };
    resultFromTrebuchet = trebuchetStage: (store {
      experimentStage = getExperimentStage trebuchetStage;
      inherit trebuchetStage;
    });
    timetable = callPackage ./pp/timetable.nix { };
    rPlot = callPackage ./pp/rplot.nix { };
    timetableFromTrebuchet = tre: timetable (resultFromTrebuchet tre);
    mergeDatasets = callPackage ./pp/merge.nix { };

    # Takes a list of experiments and returns a file that contains
    # all timetable results from the experiments.
    merge = exps: mergeDatasets (map timetableFromTrebuchet exps);

    # Automatic launcher
    launcher = callPackage ./pp/launcher.nix { };
    resultFromLauncher = l: import (builtins.readFile l);
  };

  garlicd = callPackage ./garlicd/default.nix {
    garlicTool = bsc.garlic.tool;
  };

  # Apps for Garlic
  apps = callPackage ./apps/index.nix { };

  # Experiments
  exp = callPackage ./exp/index.nix { };

  # Figures generated from the experiments
  fig = callPackage ./fig/index.nix { };

}
