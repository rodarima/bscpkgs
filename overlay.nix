self:  /* Future last stage */
super: /* Previous stage */

let
  inherit (self.lib) callPackageWith;
  inherit (self.lib) callPackagesWith;
  callPackage = callPackageWith (self // self.bsc // self.garlic);

  # --------------------------------------------------------- #
  #  BSC Packages
  # --------------------------------------------------------- #

  bsc = {
    # Default MPI implementation to use. Will be overwritten by the
    # experiments.
    mpi = self.bsc.impi;

    perf = callPackage ./bsc/perf/default.nix {
      kernel = self.linuxPackages_4_9.kernel;
      systemtap = self.linuxPackages_4_9.systemtap;
    };

    # ParaStation MPI
    pscom = callPackage ./bsc/parastation/pscom.nix { };
    psmpi = callPackage ./bsc/parastation/psmpi.nix { };

    osumb = callPackage ./bsc/osu/default.nix { };

    mpich = callPackage ./bsc/mpich/default.nix { };

    mpichDebug = self.bsc.mpich.override { enableDebug = true; };

    # Updated version of libpsm2: TODO push upstream.
    #libpsm2 = callPackage ./bsc/libpsm2/default.nix { };

    # Default Intel MPI version is 2019 (the last one)
    impi = self.bsc.intelMpi;

    intelMpi = self.bsc.intelMpi2019;

    intelMpi2019 = callPackage ./bsc/intel-mpi/default.nix {
      # Intel MPI provides a debug version of the MPI library, but
      # by default we use the release variant for performance
      enableDebug = false;
    };

    # By default we use Intel compiler 2020 update 1
    iccUnwrapped = self.bsc.icc2020Unwrapped;

    icc2020Unwrapped = callPackage ./bsc/intel-compiler/icc2020.nix {
      intel-mpi = self.bsc.intelMpi;
    };

    # A wrapper script that puts all the flags and environment vars properly and
    # calls the intel compiler binary
    icc = callPackage ./bsc/intel-compiler/default.nix {
      iccUnwrapped = self.bsc.iccUnwrapped;
      intelLicense = self.bsc.intelLicense;
    };

    # We need to set the cc.cc.CC and cc.cc.CXX attributes, in order to
    # determine the name of the compiler
    # FIXME: Use a proper and automatic way to compute the compiler name
    gcc = self.gcc.overrideAttrs (old1: {
      cc = old1.cc.overrideAttrs (old2: {
        passthru = old2.passthru // {
          CC = "gcc";
          CXX = "g++";
        };
      });
    });

    intelLicense = callPackage ./bsc/intel-compiler/license.nix { };

    pmix2 = callPackage ./bsc/pmix/pmix2.nix { };

    slurm17 = callPackage ./bsc/slurm/default.nix {
      pmix = self.bsc.pmix2;
    };

    slurm17-libpmi2 = callPackage ./bsc/slurm/pmi2.nix {
      pmix = self.bsc.pmix2;
    };

    # Use a slurm compatible with MN4
    slurm = self.bsc.slurm17;

    openmpi-mn4 = callPackage ./bsc/openmpi/default.nix {
      pmix = self.bsc.pmix2;
      pmi2 = self.bsc.slurm17-libpmi2;
      enableCxx = true;
    };

    openmpi = self.bsc.openmpi-mn4;

    fftw = callPackage ./bsc/fftw/default.nix { };

    extrae = callPackage ./bsc/extrae/default.nix { };

    tampi = self.bsc.tampiRelease;
    tampiRelease = callPackage ./bsc/tampi/default.nix { };
    tampiGit = callPackage ./bsc/tampi/git.nix { };

    mcxxGit = callPackage ./bsc/mcxx/default.nix {
      bison = self.bison_3_5;
    };

    mcxxRarias = callPackage ./bsc/mcxx/rarias.nix {
      bison = self.bison_3_5;
    };

    mcxx = self.bsc.mcxxGit;

    # Use nanos6 git by default
    nanos6 = self.bsc.nanos6Git;
    nanos6Latest = callPackage ./bsc/nanos6/default.nix { };
    nanos6Git = callPackage ./bsc/nanos6/git.nix { };

    jemalloc = self.jemalloc.overrideAttrs (old:
    {
      # Custom nanos6 configure options
      configureFlags = old.configureFlags ++ [
        "--with-jemalloc-prefix=nanos6_je_"
        "--enable-stats"
      ];
    });

    nanos6Jemalloc = callPackage ./bsc/nanos6/git.nix {
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

    clangOmpss2Unwrapped = callPackage ./bsc/llvm-ompss2/clang.nix {
      stdenv = self.llvmPackages_10.stdenv;
      enableDebug = false;
    };

    clangOmpss2 = callPackage bsc/llvm-ompss2/default.nix {
      clangOmpss2Unwrapped = self.bsc.clangOmpss2Unwrapped;
    };

    stdenvOmpss2 = self.clangStdenv.override {
      cc = self.bsc.clangOmpss2;
    };

    cpic = callPackage ./bsc/apps/cpic/default.nix {
      stdenv = self.bsc.stdenvOmpss2;
      mpi = self.bsc.mpi;
      tampi = self.bsc.tampi;
    };

    mpptest = callPackage ./bsc/mpptest/default.nix { };

    busybox = self.busybox.override {
      enableStatic = true;
    };

    groff = callPackage ./bsc/groff/default.nix { };

    nixtools = callPackage ./bsc/nixtools/default.nix { };

    garlicTools = callPackage ./garlic/tools.nix {};

    garlic = {
      # TODO: move into garlic/default.nix

      # Configuration for the machines
      machines = callPackage ./garlic/machines.nix {};

      report = callPackage ./garlic/report.nix {
        fig = self.bsc.garlic.fig;
      };

      # Use the configuration for the following target machine
      targetMachine = self.garlic.machines.mn4;

      # Load some helper functions to generate app variants

      stdexp = callPackage ./garlic/stdexp.nix {
        inherit (self.garlic) targetMachine stages;
      };

      # Apps for Garlic

      apps = {

        nbody = callPackage ./garlic/apps/nbody/default.nix {
          cc = self.bsc.icc;
          mpi = self.bsc.mpi;
          tampi = self.bsc.tampi;
          mcxx = self.bsc.mcxx;
          gitBranch = "garlic/seq";
        };

        saiph = callPackage ./garlic/apps/saiph/default.nix {
          cc = self.bsc.clangOmpss2;
        };

        creams = callPackage ./garlic/apps/creams/default.nix {
          gnuDef   = self.gfortran10 ; # Default GNU   compiler version
          intelDef = self.bsc.icc    ; # Default Intel compiler version
          gitBranch = "garlic/mpi+send+seq";
          cc  = self.bsc.icc; # self.bsc.icc OR self.gfortran10;
          mpi = self.bsc.mpi; # self.bsc.mpi OR self.bsc.openmpi-mn4;
        };

        creamsInput = callPackage ./garlic/apps/creams/input.nix {
          gitBranch = "garlic/mpi+send+seq";
        };

        hpcg = callPackage ./garlic/apps/hpcg/default.nix {
          cc = self.bsc.icc;
          mcxx = self.bsc.mcxx;
          nanos6 = self.bsc.nanos6;
          gitBranch = "garlic/oss";

          # cc = self.bsc.icc;
          # gitBranch = "garlic/seq";

          # cc = self.bsc.icc;
          # mpi = self.bsc.mpi;
          # gitBranch = "garlic/mpi";

          # cc = self.bsc.icc;
          # gitBranch = "garlic/omp";

          # cc = self.bsc.icc;
          # mpi = self.bsc.mpi;
          # gitBranch = "garlic/mpi+omp";

        };

        heat = callPackage ./garlic/apps/heat/default.nix { };
#        heat = callPackage ./garlic/apps/heat/default.nix {
#          # FIXME: The heat program must be able to compile with gcc9 and newer
#          stdenv = self.gcc7Stdenv;
#          #mpi = intel-mpi;
#          #tampi = tampi;
#
#          # FIXME: Nanos6 fails to load if we are not using a compatible stdc++
#          # version, so we use the same provided by gcc7
#          mcxx = self.bsc.mcxx.override {
#            nanos6 = self.bsc.nanos6.override {
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
        mpi = self.bsc.mpi;
      };

      hist = callPackage ./garlic/pp/hist { };

      tool = callPackage ./garlic/sh/default.nix {
        sshHost = "mn1";
      };

      # Post processing tools
      pp = with self.bsc.garlicTools; rec {
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
          tampi = callPackage ./garlic/exp/nbody/tampi.nix { };

          # Experiment variants
          medium = tampi.override { particles = 24 * 4096; };
          baseline = medium;
          freeCpu = baseline.override { freeCpu = true; };
          jemalloc = baseline.override { enableJemalloc = true; };
        };

        saiph = {
          numcomm = callPackage ./garlic/exp/saiph/numcomm.nix { };
        };

        creams = {
          ss = {
            pure = callPackage ./garlic/exp/creams/ss+pure.nix { };
            hybrid = callPackage ./garlic/exp/creams/ss+hybrid.nix { };
          };
        };

        hpcg = {
          serial = callPackage ./garlic/exp/hpcg/serial.nix { };
          mpi = callPackage ./garlic/exp/hpcg/mpi.nix { };
          omp = callPackage ./garlic/exp/hpcg/omp.nix { };
          mpi_omp = callPackage ./garlic/exp/hpcg/mpi+omp.nix { };
          input = callPackage ./garlic/exp/hpcg/gen.nix {
            inherit (self.bsc.garlic.pp) resultFromTrebuchet;
          };
          oss = callPackage ./garlic/exp/hpcg/oss.nix {
            genInput = self.bsc.garlic.exp.hpcg.input;
          };
        };

        heat = {
          test = callPackage ./garlic/exp/heat/test.nix { };
        };
      };

      # Datasets used in the figures
      ds = with self.bsc.garlic; with pp; {
        nbody = with exp.nbody; {
          baseline = merge [ baseline ];
          jemalloc = merge [ baseline jemalloc ];
          freeCpu  = merge [ baseline freeCpu ];
        };

        hpcg = with exp.hpcg; {
          oss = merge [ oss ];
        };

        saiph = with exp.saiph; {
          numcomm = merge [ numcomm ];
        };

        heat = with exp.heat; {
          test = merge [ test ];
        };
      };

      # Figures generated from the experiments
      fig = with self.bsc.garlic; {
        nbody = {
          baseline = pp.rPlot {
            script = ./garlic/fig/nbody/baseline.R;
            dataset = ds.nbody.baseline;
          };
          jemalloc = pp.rPlot {
            script = ./garlic/fig/nbody/jemalloc.R;
            dataset = ds.nbody.jemalloc;
          };
          freeCpu = pp.rPlot {
            script = ./garlic/fig/nbody/freeCpu.R;
            dataset = ds.nbody.freeCpu;
          };
        };

        hpcg = {
          oss = with ds.hpcg; pp.rPlot {
            script = ./garlic/fig/hpcg/oss.R;
            dataset = oss;
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
  };

in
  {
    bsc = bsc;

    # Aliases
    garlic = bsc.garlic;
    inherit (bsc.garlic) exp fig apps ds;
  }
