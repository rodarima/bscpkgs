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

    icc2021Unwrapped = callPackage ./bsc/intel-compiler/icc2021.nix { };

    intel-oneapi-2023 = callPackage ./bsc/intel-oneapi/2023.nix {
      libffi = self.libffi_3_3;
    };

    intel2023 = {
      inherit (bsc.intel-oneapi-2023)
        stdenv icx stdenv-ifort ifort
        # Deprecated in mid 2023
        stdenv-icc icc;
    };

    intel2022 = {
      icc = bsc.icc2021;
    };

    intel2021 = {
      icc = bsc.icc2021;
    };

    # A wrapper script that puts all the flags and environment vars
    # properly and calls the intel compiler binary
    icc2020 = appendPasstru (callPackage ./bsc/intel-compiler/default.nix {
      iccUnwrapped = bsc.iccUnwrapped;
      intelLicense = bsc.intelLicense;
    }) { CC = "icc"; CXX = "icpc"; };

    icc2021 = appendPasstru (callPackage ./bsc/intel-compiler/wrapper2021.nix {
      iccUnwrapped = bsc.icc2021Unwrapped;
    }) { CC = "icx"; CXX = "icpx"; };

    ifort2022 = callPackage ./bsc/intel-compiler/default.nix {
      iccUnwrapped = bsc.ifort2022Unwrapped;
      intelLicense = bsc.intelLicense;
    };

    icx = bsc.intel2023.icx;
    icc = bsc.intel2023.icc;
    ifort = bsc.intel2023.ifort;

    # We need to set the cc.CC and cc.CXX attributes, in order to 
    # determine the name of the compiler
    gcc = appendPasstru self.gcc { CC = "gcc"; CXX = "g++"; };

    # Last llvm release by default
    llvmPackages = self.llvmPackages_latest // {
      clang = appendPasstru self.llvmPackages_latest.clang {
        CC = "clang"; CXX = "clang++";
      };
    };

    lld = bsc.llvmPackages.lld;

    clangOmpss2Unwrapped = callPackage ./bsc/llvm-ompss2/clang.nix {
      stdenv = bsc.llvmPackages.stdenv;
    };

    clangOmpss2UnwrappedGit = bsc.clangOmpss2Unwrapped.overrideAttrs (old: rec {
      src = builtins.fetchGit {
        url = "ssh://git@bscpm03.bsc.es/llvm-ompss/llvm-mono.git";
        ref = "master";
      };
      version = src.shortRev;
    });

    clangOmpss2 = appendPasstru (
      callPackage ./bsc/llvm-ompss2/default.nix {
        rt = bsc.nanos6;
        llvmPackages = bsc.llvmPackages;
        clangOmpss2Unwrapped = bsc.clangOmpss2Unwrapped;
      }) { CC = "clang"; CXX = "clang++"; };

    clangOmpss2Git = appendPasstru (
      callPackage ./bsc/llvm-ompss2/default.nix {
        rt = bsc.nanos6;
        llvmPackages = bsc.llvmPackages;
        clangOmpss2Unwrapped = bsc.clangOmpss2UnwrappedGit;
      }) { CC = "clang"; CXX = "clang++"; };

    stdenvClangOmpss2 = self.stdenv.override {
      cc = bsc.clangOmpss2;
      allowedRequisites = null;
    };

    clangNodes = bsc.clangOmpss2.override {
      rt = bsc.nodes;
    };

    stdenvClangNodes = self.stdenv.override {
      cc = bsc.clangNodes;
      allowedRequisites = null;
    };

    mcxx = bsc.mcxxRelease;
    mcxxRelease = callPackage ./bsc/mcxx/default.nix { };
    mcxxGit = callPackage ./bsc/mcxx/git.nix { };
    mcxxRarias = callPackage ./bsc/mcxx/rarias.nix {
      bison = self.bison_3_5;
    };

    # =================================================================
    #  nanos6
    # =================================================================
    nanos6 = bsc.nanos6Release;
    nanos6Release = callPackage ./bsc/nanos6/default.nix { };
    nanos6Git = callPackage ./bsc/nanos6/default.nix { useGit = true; };
    nanos6-icx = bsc.nanos6.override {
      stdenv = bsc.intel2023.stdenv;
    };
    nanos6-icc = bsc.nanos6.override {
      stdenv = bsc.intel2023.stdenv-icc;
    };

    nanos6Debug = bsc.nanos6.overrideAttrs (old: {
      dontStrip = true;
      enableDebugging = true;
    });

    nanos6GlibcxxDebug = bsc.nanos6Debug.override {
      enableGlibcxxDebug = true;
    };

    jemalloc = self.jemalloc.overrideAttrs (old:
    {
      # Custom nanos6 configure options
      configureFlags = old.configureFlags ++ [
        "--with-jemalloc-prefix=nanos6_je_"
        "--enable-stats"
      ];

      hardeningDisable = [ "all" ];
    });

    nodes = bsc.nodesRelease;
    nodesRelease = callPackage ./bsc/nodes/default.nix { };
    nodesGit = callPackage ./bsc/nodes/default.nix { useGit = true; };
    nodesWithOvni = bsc.nodes.override { enableOvni = true; };

    # =================================================================
    #  nosv
    # =================================================================
    nosv = callPackage ./bsc/nosv/default.nix { };

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
    #mpich_3 = callPackage ./bsc/mpich/default.nix { };
    #mpichDebug_3 = bsc.mpich.override { enableDebug = true; };
    mpich = super.mpich.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [ self.libfabric ];
      configureFlags = old.configureFlags ++ [
        "--with-device=ch4:ofi"
        "--with-libfabric=${self.libfabric}"
      ];
      hardeningDisable = [ "all" ];
    });

    impi = bsc.intel-mpi;
    # The version of MPI for 2023 is labeled 2021.9 ...
    intel-mpi = bsc.intel-oneapi-2023.intel-mpi;
    # Old releases
    intel-mpi-2019 = callPackage ./bsc/intel-mpi/default.nix { };

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
    #  GASPI
    # =================================================================
    gpi-2 = callPackage ./bsc/gpi-2/default.nix { };

    # Use GPI-2 as the default implementation for GASPI
    gaspi = bsc.gpi-2;

    tagaspi = callPackage ./bsc/tagaspi/default.nix { };

    # =================================================================
    #  Tracing
    # =================================================================

    paraverKernel = callPackage ./bsc/paraver/kernel.nix { };
    wxparaver = callPackage ./bsc/paraver/default.nix { };

    # We should maintain these...
    paraverKernelFast = callPackage ./bsc/paraver/kernel-fast.nix { };
    wxparaverFast = callPackage ./bsc/paraver/wxparaver-fast.nix { };

    extrae = callPackage ./bsc/extrae/default.nix {
      libdwarf = super.libdwarf_20210528;
    };
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
    ovni = callPackage ./bsc/ovni/default.nix { };

    # =================================================================
    #  MN4 specific
    # =================================================================

    osumb = callPackage ./bsc/osu/default.nix { };
    lmbench = callPackage ./bsc/lmbench/default.nix { };
    pmix2 = callPackage ./bsc/pmix/pmix2.nix { };
    slurm17 = callPackage ./bsc/slurm/default.nix {
      pmix = bsc.pmix2;
    };
    slurm17-libpmi2 = callPackage ./bsc/slurm/pmi2.nix {
      pmix = bsc.pmix2;
    };

    slurm-16-05-8-1 = callPackage ./bsc/slurm/16.05.8.1/default.nix {
      hwloc = bsc.hwloc-1-11-6;
    };

    hwloc-1-11-6 = callPackage ./bsc/hwloc/1.11.6/default.nix {};

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
    cpuid = callPackage ./bsc/cpuid/default.nix { };
    bench6 = callPackage ./bsc/bench6/default.nix { };

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

    test = rec {
#      hwloc = callPackage ./test/bugs/hwloc.nix { };
      sigsegv = callPackage ./test/reproducers/sigsegv.nix { };
      compilers.hello-c = callPackage ./test/compilers/hello-c.nix { };
      compilers.hello-cpp = callPackage ./test/compilers/hello-cpp.nix { };
      compilers.hello-f = callPackage ./test/compilers/hello-f.nix { };
      compilers.lto = callPackage ./test/compilers/lto.nix { };
      compilers.intel2023.icx.c = compilers.hello-c.override {
        stdenv = bsc.intel2023.stdenv;
      };
      compilers.intel2023.icc.c = compilers.hello-c.override {
        stdenv = bsc.intel2023.stdenv-icc;
      };
      compilers.intel2023.icx.cpp = compilers.hello-cpp.override {
        stdenv = bsc.intel2023.stdenv;
      };
      compilers.intel2023.icc.cpp = compilers.hello-cpp.override {
        stdenv = bsc.intel2023.stdenv-icc;
      };
      compilers.intel2023.ifort = compilers.hello-f.override {
        stdenv = bsc.intel2023.stdenv-ifort;
      };
      compilers.clangOmpss2.lto = compilers.lto.override {
        stdenv = bsc.stdenvClangOmpss2;
      };
      compilers.clangOmpss2.task = callPackage ./test/compilers/ompss2.nix {
        stdenv = bsc.stdenvClangOmpss2;
      };
      compilers.clangNodes.task = callPackage ./test/compilers/ompss2.nix {
        stdenv = bsc.stdenvClangNodes;
      };
    };

    testAll = with bsc.test; [
      compilers.intel2023.icx.c
      compilers.intel2023.icc.c
      compilers.intel2023.icx.cpp
      compilers.intel2023.icc.cpp
      compilers.intel2023.ifort
      compilers.clangOmpss2.lto
      compilers.clangOmpss2.task
      compilers.clangNodes.task
    ];

    ci = import ./test/ci.nix {
      inherit self super bsc callPackage;
    };
  });

in
  {
    bsc = _bsc;
    garlic = _bsc.garlic;

    # Aliases apps -> bsc.garlic.apps
    inherit (_bsc.garlic) apps fig exp ds;
  }
