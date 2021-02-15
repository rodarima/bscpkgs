self:  /* Future last stage */
super: /* Previous stage */

with self.lib;

let
  inherit (self.lib) callPackageWith;
  inherit (self.lib) callPackagesWith;

  appendPasstru = drv: attrs: drv.overrideAttrs (old:{
    passthru = old.passthru // attrs;
  });

  # ===================================================================
  #  BSC Packages
  # ===================================================================

  _bsc = makeExtensible (bsc:
  let
    callPackage = callPackageWith (self // bsc // bsc.garlic);
  in
  {
    inherit callPackage;

    # =================================================================
    #  Compilers                                                    
    # =================================================================

    # Default C (and C++) compiler to use. It will be overwritten by the
    # experiments.
    cc = bsc.icc;

    # By default we use Intel compiler 2020 update 1
    intelLicense = callPackage ./bsc/intel-compiler/license.nix { };
    iccUnwrapped = bsc.icc2020Unwrapped;
    icc2020Unwrapped = callPackage ./bsc/intel-compiler/icc2020.nix {
      intel-mpi = bsc.intelMpi;
    };

    # A wrapper script that puts all the flags and environment vars
    # properly and calls the intel compiler binary
    icc = appendPasstru (callPackage ./bsc/intel-compiler/default.nix {
      iccUnwrapped = bsc.iccUnwrapped;
      intelLicense = bsc.intelLicense;
    }) { CC = "icc"; CXX = "icpc"; };

    # We need to set the cc.CC and cc.CXX attributes, in order to 
    # determine the name of the compiler
    gcc = appendPasstru self.gcc { CC = "gcc"; CXX = "g++"; };

    # Last llvm release by default
    llvmPackages = self.llvmPackages_11 // {
      clang = appendPasstru self.llvmPackages_11.clang {
        CC = "clang"; CXX = "clang++";
      };
    };

    lld = bsc.llvmPackages.lld;

    clangOmpss2Unwrapped = callPackage ./bsc/llvm-ompss2/clang.nix {
      stdenv = bsc.llvmPackages.stdenv;
    };

    clangOmpss2 = appendPasstru (
      callPackage ./bsc/llvm-ompss2/default.nix {
        clangOmpss2Unwrapped = bsc.clangOmpss2Unwrapped;
      }) { CC = "clang"; CXX = "clang++"; };

    mcxx = bsc.mcxxRelease;
    mcxxRelease = callPackage ./bsc/mcxx/default.nix { };
    mcxxRarias = callPackage ./bsc/mcxx/rarias.nix {
      bison = self.bison_3_5;
    };

    # =================================================================
    #  nanos6
    # =================================================================
    nanos6 = bsc.nanos6Release;
    nanos6Release = callPackage ./bsc/nanos6/default.nix { };
    nanos6Git = callPackage ./bsc/nanos6/git.nix { };
    nanos6Debug = bsc.nanos6.overrideAttrs (old: {
      dontStrip = true;
      enableDebugging = true;
    });
    nanos6Jemalloc = bsc.nanos6.override { enableJemalloc = true; };

    jemalloc = self.jemalloc.overrideAttrs (old:
    {
      # Custom nanos6 configure options
      configureFlags = old.configureFlags ++ [
        "--with-jemalloc-prefix=nanos6_je_"
        "--enable-stats"
      ];
    });

    # =================================================================
    #  MPI
    # =================================================================

    # Default MPI implementation to use. Will be overwritten by the
    # experiments.
    mpi = bsc.impi;

    # ParaStation MPI
    pscom = callPackage ./bsc/parastation/pscom.nix { };
    psmpi = callPackage ./bsc/parastation/psmpi.nix { };

    # MPICH
    mpich = callPackage ./bsc/mpich/default.nix { };
    mpichDebug = bsc.mpich.override { enableDebug = true; };

    # Default Intel MPI version is 2019 (the last one)
    impi = bsc.intelMpi;
    intelMpi = bsc.intelMpi2019;
    intelMpi2019 = callPackage ./bsc/intel-mpi/default.nix { };

    # OpenMPI
    openmpi = bsc.openmpi-mn4;
    openmpi-mn4 = callPackage ./bsc/openmpi/default.nix {
      pmix = bsc.pmix2;
      pmi2 = bsc.slurm17-libpmi2;
      enableCxx = true;
    };

    # TAMPI
    tampi = bsc.tampiRelease;
    tampiRelease = callPackage ./bsc/tampi/default.nix { };
    tampiGit = callPackage ./bsc/tampi/git.nix { };

    # =================================================================
    #  Tracing
    # =================================================================

    wxpropgrid = callPackage ./bsc/wxpropgrid/default.nix { };
    paraver = callPackage ./bsc/paraver/default.nix { };
    paraverExtra = bsc.paraver.override { enableMouseLabel = true; };
    paraverDebug = bsc.paraver.overrideAttrs (old: {
      dontStrip = true;
      enableDebugging = true;
    });

    extrae = callPackage ./bsc/extrae/default.nix { };
    otf = callPackage ./bsc/otf/default.nix { };
    vite = self.qt5.callPackage ./bsc/vite/default.nix { };
    babeltrace = callPackage ./bsc/babeltrace/default.nix { };
    babeltrace2 = callPackage ./bsc/babeltrace2/default.nix { };

    # Perf for MN4 kernel
    perf = callPackage ./bsc/perf/default.nix {
      kernel = self.linuxPackages_4_9.kernel;
      systemtap = self.linuxPackages_4_9.systemtap;
    };

    cn6 = callPackage ./bsc/cn6/default.nix { };

    # =================================================================
    #  MN4 specific
    # =================================================================

    osumb = callPackage ./bsc/osu/default.nix { };
    pmix2 = callPackage ./bsc/pmix/pmix2.nix { };
    slurm17 = callPackage ./bsc/slurm/default.nix {
      pmix = bsc.pmix2;
    };
    slurm17-libpmi2 = callPackage ./bsc/slurm/pmi2.nix {
      pmix = bsc.pmix2;
    };
    # Use a slurm compatible with MN4
    slurm = bsc.slurm17;
    # We need the unstable branch to get the fallocate problem fixed, as it is
    # not yet in stable nix, see:
    # https://pm.bsc.es/gitlab/rarias/bscpkgs/-/issues/83
    nix-mn4 = self.nixUnstable;
    # Our custom version that lacks the binaries. Disabled by default.
    #rdma-core = callPackage ./bsc/rdma-core/default.nix { };

    # =================================================================
    #  Patched from upstream
    # =================================================================

    groff = callPackage ./bsc/groff/default.nix { };
    fftw = callPackage ./bsc/fftw/default.nix { };
    vtk = callPackage ./bsc/vtk/default.nix {
      inherit (self.xorg) libX11 xorgproto libXt;
    };

    busybox = self.busybox.override {
      enableStatic = true;
    };

    # =================================================================
    #  Misc
    # =================================================================

    dummy = callPackage ./bsc/dummy/default.nix { };
    mpptest = callPackage ./bsc/mpptest/default.nix { };

    # =================================================================
    #  Garlic benchmark
    # =================================================================

    nixtools = callPackage ./bsc/nixtools/default.nix { };

    garlicTools = callPackage ./garlic/tools.nix {};

    # Aliases bsc.apps -> bsc.garlic.apps
    inherit (bsc.garlic) apps fig exp ds;

    garlic = import ./garlic/index.nix {
      inherit self super bsc callPackage;
    };

#    test = {
#      hwloc = callPackage ./test/bugs/hwloc.nix { };
#    };
  });

in
  {
    bsc = _bsc;
    garlic = _bsc.garlic;

    # Aliases apps -> bsc.garlic.apps
    inherit (_bsc.garlic) apps fig exp ds;
  }
