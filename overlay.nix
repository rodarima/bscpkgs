final: /* Future last stage */
prev:  /* Previous stage */

with final.lib;

let
  callPackage = final.callPackage;

  mkDeps = name: pkgs: final.runCommand name { }
    "printf '%s\n' ${toString (collect (x: x ? outPath) pkgs)} > $out";

  bscPkgs = {
    bench6 = callPackage ./pkgs/bench6/default.nix { };
    clangOmpss2 = callPackage ./pkgs/llvm-ompss2/default.nix { };
    clangOmpss2Nanos6 = callPackage ./pkgs/llvm-ompss2/default.nix { ompss2rt = final.nanos6; };
    clangOmpss2Nodes = callPackage ./pkgs/llvm-ompss2/default.nix { ompss2rt = final.nodes; };
    clangOmpss2OpenmpNodes = callPackage ./pkgs/llvm-ompss2/default.nix { ompss2rt = final.nodes; clangOmpss2Unwrapped = final.clangOmpss2OpenmpUnwrapped; };
    clangOmpss2Unwrapped = callPackage ./pkgs/llvm-ompss2/clang.nix { };
    clangOmpss2OpenmpUnwrapped = callPackage ./pkgs/llvm-ompss2/openmp.nix { clangOmpss2Unwrapped = final.clangOmpss2Unwrapped; };
    #extrae = callPackage ./pkgs/extrae/default.nix { }; # Broken and outdated
    gpi-2 = callPackage ./pkgs/gpi-2/default.nix { };
    intelPackages_2023 = callPackage ./pkgs/intel-oneapi/2023.nix { };
    jemallocNanos6 = callPackage ./pkgs/nanos6/jemalloc.nix { };
    #lmbench = callPackage ./pkgs/lmbench/default.nix { }; # Broken
    mcxx = callPackage ./pkgs/mcxx/default.nix { };
    nanos6 = callPackage ./pkgs/nanos6/default.nix { };
    nanos6Debug = final.nanos6.override { enableDebug = true; };
    nixtools = callPackage ./pkgs/nixtools/default.nix { };
    nix-wrap = callPackage ./pkgs/nix-wrap/default.nix { };
    nodes = callPackage ./pkgs/nodes/default.nix { };
    nosv = callPackage ./pkgs/nosv/default.nix { };
    osumb = callPackage ./pkgs/osu/default.nix { };
    ovni = callPackage ./pkgs/ovni/default.nix { };
    ovniGit = final.ovni.override { useGit = true; };
    paraverKernel = callPackage ./pkgs/paraver/kernel.nix { };
    #paraverKernelFast = callPackage ./pkgs/paraver/kernel-fast.nix { }; # Outdated
    #pscom = callPackage ./pkgs/parastation/pscom.nix { }; # Unmaintaned
    #psmpi = callPackage ./pkgs/parastation/psmpi.nix { }; # Unmaintaned
    sonar = callPackage ./pkgs/sonar/default.nix { };
    stdenvClangOmpss2 = final.stdenv.override { cc = final.clangOmpss2; allowedRequisites = null; };
    stdenvClangOmpss2Nanos6 = final.stdenv.override { cc = final.clangOmpss2Nanos6; allowedRequisites = null; };
    stdenvClangOmpss2Nodes = final.stdenv.override { cc = final.clangOmpss2Nodes; allowedRequisites = null; };
    stdenvClangOmpss2OpenmpNodes = final.stdenv.override { cc = final.clangOmpss2OpenmpNodes; allowedRequisites = null; };
    tagaspi = callPackage ./pkgs/tagaspi/default.nix { };
    tampi = callPackage ./pkgs/tampi/default.nix { };
    wxparaver = callPackage ./pkgs/paraver/default.nix { };
    #wxparaverFast = callPackage ./pkgs/paraver/wxparaver-fast.nix { }; # Outdated
  };

in bscPkgs // {
  # Prevent accidental usage of bsc attribute
  bsc = throw "the bsc attribute is deprecated, packages are now in the root";

  # Internal for our CI tests
  bsc-ci = {
    test = rec {
      #hwloc = callPackage ./test/bugs/hwloc.nix { }; # Broken, no /sys
      #sigsegv = callPackage ./test/reproducers/sigsegv.nix { };
      hello-c = callPackage ./test/compilers/hello-c.nix { };
      hello-cpp = callPackage ./test/compilers/hello-cpp.nix { };
      lto = callPackage ./test/compilers/lto.nix { };
      asan = callPackage ./test/compilers/asan.nix { };
      intel2023-icx-c   = hello-c.override   { stdenv = final.intelPackages_2023.stdenv; };
      intel2023-icc-c   = hello-c.override   { stdenv = final.intelPackages_2023.stdenv-icc; };
      intel2023-icx-cpp = hello-cpp.override { stdenv = final.intelPackages_2023.stdenv; };
      intel2023-icc-cpp = hello-cpp.override { stdenv = final.intelPackages_2023.stdenv-icc; };
      intel2023-ifort   = callPackage ./test/compilers/hello-f.nix {
        stdenv = final.intelPackages_2023.stdenv-ifort;
      };
      clangOmpss2-lto   = lto.override       { stdenv = final.stdenvClangOmpss2Nanos6; };
      clangOmpss2-asan  = asan.override      { stdenv = final.stdenvClangOmpss2Nanos6; };
      clangOmpss2-task  = callPackage ./test/compilers/ompss2.nix {
        stdenv = final.stdenvClangOmpss2Nanos6;
      };
      clangNodes-task = callPackage ./test/compilers/ompss2.nix {
        stdenv = final.stdenvClangOmpss2Nodes;
      };
      clangNosvOpenmp-task = callPackage ./test/compilers/clang-openmp.nix {
        stdenv = final.stdenvClangOmpss2OpenmpNodes;
      };
    };

    pkgs = final.runCommand "ci-pkgs" { }
      "printf '%s\n' ${toString (collect isDerivation bscPkgs)} > $out";

    tests = final.runCommand "ci-tests" { }
      "printf '%s\n' ${toString (collect isDerivation final.bsc-ci.test)} > $out";

    all = final.runCommand "ci-all" { }
    ''
      deps="${toString [ final.bsc-ci.pkgs final.bsc-ci.tests ]}"
      cat $deps
      printf '%s\n' $deps > $out
    '';
  };
}
