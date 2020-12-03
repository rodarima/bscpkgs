self:  /* Future last stage */
super: /* Previous stage */

with self.lib;

let
  inherit (self.lib) callPackageWith;
  inherit (self.lib) callPackagesWith;
  callPackage = callPackageWith (self // self.bsc // self.garlic);

  appendPasstru = drv: attrs: drv.overrideAttrs (old:{
    passthru = old.passthru // attrs;
  });

  # --------------------------------------------------------- #
  #  BSC Packages
  # --------------------------------------------------------- #

  _bsc = makeExtensible (bsc: {
    # Default MPI implementation to use. Will be overwritten by the
    # experiments.
    mpi = bsc.impi;

    perf = callPackage ./bsc/perf/default.nix {
      kernel = self.linuxPackages_4_9.kernel;
      systemtap = self.linuxPackages_4_9.systemtap;
    };

    # ParaStation MPI
    pscom = callPackage ./bsc/parastation/pscom.nix { };
    psmpi = callPackage ./bsc/parastation/psmpi.nix { };

    osumb = callPackage ./bsc/osu/default.nix { };

    mpich = callPackage ./bsc/mpich/default.nix { };

    mpichDebug = bsc.mpich.override { enableDebug = true; };

    # Updated version of libpsm2: TODO push upstream.
    #libpsm2 = callPackage ./bsc/libpsm2/default.nix { };

    # Default Intel MPI version is 2019 (the last one)
    impi = bsc.intelMpi;

    intelMpi = bsc.intelMpi2019;

    intelMpi2019 = callPackage ./bsc/intel-mpi/default.nix {
      # Intel MPI provides a debug version of the MPI library, but
      # by default we use the release variant for performance
      enableDebug = false;
    };

    # By default we use Intel compiler 2020 update 1
    iccUnwrapped = bsc.icc2020Unwrapped;

    icc2020Unwrapped = callPackage ./bsc/intel-compiler/icc2020.nix {
      intel-mpi = bsc.intelMpi;
    };

    # A wrapper script that puts all the flags and environment vars properly and
    # calls the intel compiler binary
    icc = appendPasstru (callPackage ./bsc/intel-compiler/default.nix {
      iccUnwrapped = bsc.iccUnwrapped;
      intelLicense = bsc.intelLicense;
    }) { CC = "icc"; CXX = "icpc"; };

    # We need to set the cc.CC and cc.CXX attributes, in order to 
    # determine the name of the compiler
    gcc = appendPasstru self.gcc { CC = "gcc"; CXX = "g++"; };

    intelLicense = callPackage ./bsc/intel-compiler/license.nix { };

    pmix2 = callPackage ./bsc/pmix/pmix2.nix { };

    slurm17 = callPackage ./bsc/slurm/default.nix {
      pmix = bsc.pmix2;
    };

    slurm17-libpmi2 = callPackage ./bsc/slurm/pmi2.nix {
      pmix = bsc.pmix2;
    };

    # Use a slurm compatible with MN4
    slurm = bsc.slurm17;

    openmpi-mn4 = callPackage ./bsc/openmpi/default.nix {
      pmix = bsc.pmix2;
      pmi2 = bsc.slurm17-libpmi2;
      enableCxx = true;
    };

    openmpi = bsc.openmpi-mn4;

    fftw = callPackage ./bsc/fftw/default.nix { };

    otf = callPackage ./bsc/otf/default.nix { };
    vite = self.qt5.callPackage ./bsc/vite/default.nix { };

    wxpropgrid = callPackage ./bsc/wxpropgrid/default.nix { };
    paraver = callPackage ./bsc/paraver/default.nix { };
    paraverExtra = bsc.paraver.override { enableMouseLabel = true; };
    paraverDebug = bsc.paraver.overrideAttrs (old:
    {
      dontStrip = true;
      enableDebugging = true;
    });

    extrae = callPackage ./bsc/extrae/default.nix { };

    tampi = bsc.tampiRelease;
    tampiRelease = callPackage ./bsc/tampi/default.nix { };
    tampiGit = callPackage ./bsc/tampi/git.nix { };

    mcxx = bsc.mcxxRelease;
    mcxxRelease = callPackage ./bsc/mcxx/default.nix { };
    mcxxRarias = callPackage ./bsc/mcxx/rarias.nix {
      bison = self.bison_3_5;
    };

    nanos6 = bsc.nanos6Release;
    nanos6Release = callPackage ./bsc/nanos6/default.nix { };
    nanos6Git = callPackage ./bsc/nanos6/git.nix { };

    jemalloc = self.jemalloc.overrideAttrs (old:
    {
      # Custom nanos6 configure options
      configureFlags = old.configureFlags ++ [
        "--with-jemalloc-prefix=nanos6_je_"
        "--enable-stats"
      ];
    });

    nanos6Jemalloc = bsc.nanos6.override {
      enableJemalloc = true;
    };

    babeltrace = callPackage ./bsc/babeltrace/default.nix { };
    babeltrace2 = callPackage ./bsc/babeltrace2/default.nix { };

    vtk = callPackage ./bsc/vtk/default.nix {
      inherit (self.xorg) libX11 xorgproto libXt;
    };

    dummy = callPackage ./bsc/dummy/default.nix { };

    # Our custom version that lacks the binaries. Disabled by default.
    #rdma-core = callPackage ./bsc/rdma-core/default.nix { };

    # Last llvm release by default
    llvmPackages = self.llvmPackages_11 // {
      clang = appendPasstru self.llvmPackages_11.clang {
        CC = "clang"; CXX = "clang++";
      };
    };

    lld = bsc.llvmPackages.lld;

    clangOmpss2Unwrapped = callPackage ./bsc/llvm-ompss2/clang.nix {
      stdenv = bsc.llvmPackages.stdenv;
      enableDebug = false;
    };

    clangOmpss2 = appendPasstru (callPackage bsc/llvm-ompss2/default.nix {
      clangOmpss2Unwrapped = bsc.clangOmpss2Unwrapped;
    }) { CC = "clang"; CXX = "clang++"; };

    stdenvOmpss2 = self.clangStdenv.override {
      cc = bsc.clangOmpss2;
    };

    cpic = callPackage ./bsc/apps/cpic/default.nix {
      stdenv = bsc.stdenvOmpss2;
      mpi = bsc.mpi;
      tampi = bsc.tampi;
    };

    mpptest = callPackage ./bsc/mpptest/default.nix { };

    busybox = self.busybox.override {
      enableStatic = true;
    };

    groff = callPackage ./bsc/groff/default.nix { };

    nixtools = callPackage ./bsc/nixtools/default.nix { };

    garlicTools = callPackage ./garlic/tools.nix {};

    # Aliases bsc.apps -> bsc.garlic.apps
    inherit (bsc.garlic) apps fig exp ds;

    # TODO: move into garlic/default.nix
    garlic = {

      unsafeDevelop = callPackage ./garlic/develop/default.nix {
            extraInputs = with self; [
              coreutils htop procps-ng vim which strace
              tmux gdb kakoune universal-ctags bashInteractive
              glibcLocales ncurses git screen curl
              # Add more nixpkgs packages here...
              bsc.slurm bsc.clangOmpss2 bsc.icc bsc.mcxx bsc.perf
              # Add more bscpkgs packages here...
            ];
      };

      develop = bsc.garlic.stages.exec rec {
        nextStage = bsc.garlic.stages.isolate {
          nextStage = bsc.garlic.unsafeDevelop;
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

      # Configuration for the machines
      machines = callPackage ./garlic/machines.nix { };

      report = callPackage ./garlic/report.nix {
        fig = bsc.garlic.fig;
      };

      sedReport = callPackage ./garlic/sedReport.nix {
        fig = bsc.garlic.fig;
      };

      bundleReport = callPackage ./garlic/bundleReport.nix {
        fig = bsc.garlic.fig;
      };

      reportTar = callPackage ./garlic/reportTar.nix {
        fig = bsc.garlic.fig;
      };

      # Use the configuration for the following target machine
      targetMachine = bsc.garlic.machines.mn4;

      # Load some helper functions to generate app variants

      stdexp = callPackage ./garlic/stdexp.nix {
        inherit (bsc.garlic) targetMachine stages;
      };

      # Apps for Garlic

      apps = {

        nbody = callPackage ./garlic/apps/nbody/default.nix {
          cc = bsc.icc;
          mpi = bsc.mpi;
          tampi = bsc.tampi;
          mcxx = bsc.mcxx;
          gitBranch = "garlic/seq";
        };

        saiph = callPackage ./garlic/apps/saiph/default.nix {
          cc = bsc.clangOmpss2;
        };

        creams = callPackage ./garlic/apps/creams/default.nix {
          gnuDef   = self.gfortran10 ; # Default GNU   compiler version
          intelDef = bsc.icc    ; # Default Intel compiler version
          gitBranch = "garlic/mpi+send+seq";
          cc  = bsc.icc; # bsc.icc OR self.gfortran10;
          mpi = bsc.mpi; # bsc.mpi OR bsc.openmpi-mn4;
        };

        creamsInput = callPackage ./garlic/apps/creams/input.nix {
          gitBranch = "garlic/mpi+send+seq";
        };

        hpcg = callPackage ./garlic/apps/hpcg/default.nix {
          cc = bsc.icc;
          mcxx = bsc.mcxx;
          nanos6 = bsc.nanos6;
          gitBranch = "garlic/oss";
        };

        bigsort = {
          sort = callPackage ./garlic/apps/bigsort/default.nix {
            gitBranch = "garlic/mpi+send+omp+task";
            cc = bsc.icc;
          };

          genseq = callPackage ./garlic/apps/bigsort/genseq.nix {
            cc = bsc.icc;
          };

          shuffle = callPackage ./garlic/apps/bigsort/shuffle.nix {
            cc = bsc.icc;
          };
        };

        heat = callPackage ./garlic/apps/heat/default.nix { };

        miniamr = callPackage ./garlic/apps/miniamr/default.nix {
          variant = "ompss-2";
        };

        ifsker = callPackage ./garlic/apps/ifsker/default.nix { };

#        heat = callPackage ./garlic/apps/heat/default.nix {
#          # FIXME: The heat program must be able to compile with gcc9 and newer
#          stdenv = self.gcc7Stdenv;
#          #mpi = intel-mpi;
#          #tampi = tampi;
#
#          # FIXME: Nanos6 fails to load if we are not using a compatible stdc++
#          # version, so we use the same provided by gcc7
#          mcxx = bsc.mcxx.override {
#            nanos6 = bsc.nanos6.override {
#              stdenv = self.gcc7Stdenv;
#            };
#          };
#        };
#  
#        lulesh = callPackage ./garlic/apps/lulesh {
#          mpi = intel-mpi;
#        };
#  
#        hpccg = callPackage ./garlic/apps/hpccg { };
#  
#        fwi = callPackage ./garlic/apps/fwi { };
      };

      # Execution stages
      stages = {
        sbatch     = callPackage ./garlic/stages/sbatch.nix { };
        srun       = callPackage ./garlic/stages/srun.nix { };
        control    = callPackage ./garlic/stages/control.nix { };
        exec       = callPackage ./garlic/stages/exec.nix { };
        extrae     = callPackage ./garlic/stages/extrae.nix { };
        valgrind   = callPackage ./garlic/stages/valgrind.nix { };
        perf       = callPackage ./garlic/stages/perf.nix { };
        isolate    = callPackage ./garlic/stages/isolate { };
        runexp     = callPackage ./garlic/stages/runexp { };
        trebuchet  = callPackage ./garlic/stages/trebuchet.nix { };
        strace     = callPackage ./garlic/stages/strace.nix { };
        unit       = callPackage ./garlic/stages/unit.nix { };
        experiment = callPackage ./garlic/stages/experiment.nix { };
      };

      # Tests (move to bsc ?)
      mpptest = callPackage ./garlic/mpptest { };

      ppong = callPackage ./garlic/ppong {
        mpi = bsc.mpi;
      };

      hist = callPackage ./garlic/pp/hist { };

      tool = callPackage ./garlic/sh/default.nix {
        sshHost = "mn1";
      };

      # Post processing tools
      pp = with bsc.garlicTools; rec {
        store = callPackage ./garlic/pp/store.nix { };
        resultFromTrebuchet = trebuchetStage: (store {
          experimentStage = getExperimentStage trebuchetStage;
          inherit trebuchetStage;
        });
        timetable = callPackage ./garlic/pp/timetable.nix { };
        rPlot = callPackage ./garlic/pp/rplot.nix { };
        timetableFromTrebuchet = tre: timetable (resultFromTrebuchet tre);
        mergeDatasets = callPackage ./garlic/pp/merge.nix { };

        # Takes a list of experiments and returns a file that contains
        # all timetable results from the experiments.
        merge = exps: mergeDatasets (map timetableFromTrebuchet exps);
      };

      # Experiments
      exp = {
        nbody = rec {
          baseline = callPackage ./garlic/exp/nbody/nblocks.nix { };

          # Experiment variants
          small = baseline.override {
            particles = 12 * 4096;
          };
          # TODO: Update freeCpu using a non-standard pipeline
          #freeCpu = baseline.override { freeCpu = true; };
          jemalloc = baseline.override { enableJemalloc = true; };

          # Some experiments with traces
          trace = {
            # Only one unit repeated 30 times
            baseline = small.override {
              enableCTF = true;
              loops = 30;
              steps = 1;
            };

            # Same but with jemalloc enabled
            jemalloc = trace.baseline.override {
              enableJemalloc = true;
            };
          };
        };

        saiph = {
          numcomm = callPackage ./garlic/exp/saiph/numcomm.nix { };
          granularity = callPackage ./garlic/exp/saiph/granularity.nix { };
        };

        creams = {
          ss = {
            pure = callPackage ./garlic/exp/creams/ss+pure.nix { };
            hybrid = callPackage ./garlic/exp/creams/ss+hybrid.nix { };
          };
        };

        hpcg = rec {
          #serial = callPackage ./garlic/exp/hpcg/serial.nix { };
          #mpi = callPackage ./garlic/exp/hpcg/mpi.nix { };
          #omp = callPackage ./garlic/exp/hpcg/omp.nix { };
          #mpi_omp = callPackage ./garlic/exp/hpcg/mpi+omp.nix { };
          #input = callPackage ./garlic/exp/hpcg/gen.nix {
          #  inherit (bsc.garlic.pp) resultFromTrebuchet;
          #};
          genInput = callPackage ./garlic/exp/hpcg/gen.nix {
            inherit (bsc.garlic.pp) resultFromTrebuchet;
          };

          oss = callPackage ./garlic/exp/hpcg/oss.nix {
            inherit genInput;
          };
        };

        heat = {
          test = callPackage ./garlic/exp/heat/test.nix { };
        };

	bigsort = rec {
          genseq = callPackage ./garlic/exp/bigsort/genseq.nix {
            n = toString (1024 * 1024 * 1024 / 8); # 1 GB input size
            dram = toString (1024 * 1024 * 1024); # 1 GB chunk
          };

          shuffle = callPackage ./garlic/exp/bigsort/shuffle.nix {
            inputTre = genseq;
            n = toString (1024 * 1024 * 1024 / 8); # 1 GB input size
            dram = toString (1024 * 1024 * 1024); # 1 GB chunk
            inherit (bsc.garlic.pp) resultFromTrebuchet;
          };

          sort = callPackage ./garlic/exp/bigsort/sort.nix {
            inputTre = shuffle;
            inherit (bsc.garlic.pp) resultFromTrebuchet;
            removeOutput = false;
          };
	};

        slurm = {
          cpu = callPackage ./garlic/exp/slurm/cpu.nix { };
        };
      };

      allExperiments = self.writeText "experiments.json"
        (builtins.toJSON bsc.garlic.exp);

      # Datasets used in the figures
      ds = with bsc.garlic; with pp; {
        nbody = with exp.nbody; {
          baseline = merge [ baseline ];
          small = merge [ small ];
          jemalloc = merge [ baseline jemalloc ];
          #freeCpu  = merge [ baseline freeCpu ];
          ctf = merge [ ctf ];
        };

        hpcg = with exp.hpcg; {
          oss = merge [ oss ];
        };

        saiph = with exp.saiph; {
          numcomm = merge [ numcomm ];
          granularity = merge [ granularity ];
        };

        heat = with exp.heat; {
          test = merge [ test ];
        };

        creams = with exp.creams.ss; {
          ss.hybrid = merge [ hybrid ];
          ss.pure = merge [ pure ];
        };
      };

      # Figures generated from the experiments
      fig = with bsc.garlic; {
        nbody = {
          baseline = pp.rPlot {
            script = ./garlic/fig/nbody/baseline.R;
            dataset = ds.nbody.baseline;
          };
          small = pp.rPlot {
            script = ./garlic/fig/nbody/baseline.R;
            dataset = ds.nbody.small;
          };
          jemalloc = pp.rPlot {
            script = ./garlic/fig/nbody/jemalloc.R;
            dataset = ds.nbody.jemalloc;
          };
          #freeCpu = pp.rPlot {
          #  script = ./garlic/fig/nbody/freeCpu.R;
          #  dataset = ds.nbody.freeCpu;
          #};
          ctf = pp.rPlot {
            script = ./garlic/fig/nbody/baseline.R;
            dataset = ds.nbody.ctf;
          };
        };

        hpcg = {
          oss = with ds.hpcg; pp.rPlot {
            script = ./garlic/fig/hpcg/oss.R;
            dataset = oss;
          };
        };

        saiph = {
          granularity = with ds.saiph; pp.rPlot {
            script = ./garlic/fig/saiph/granularity.R;
	    dataset = granularity;
          };
        };

        heat = {
          test = with ds.heat; pp.rPlot {
            script = ./garlic/fig/heat/test.R;
            dataset = test;
          };
        };
      };
    };
  });

in
  {
    bsc = _bsc;
    garlic = _bsc.garlic;

    # Aliases apps -> bsc.garlic.apps
    inherit (_bsc.garlic) apps fig exp ds;
  }
