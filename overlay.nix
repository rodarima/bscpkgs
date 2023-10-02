final: /* Future last stage */
prev:  /* Previous stage */

with final.lib;

let
  callPackage = final.callPackage;

  mkDeps = name: pkgs: final.runCommand name { }
    "printf '%s\n' ${toString (collect (x: x ? outPath) pkgs)} > $out";

  bscPkgs = {
    #bench6 = callPackage ./bsc/bench6/default.nix { };
    clangOmpss2 = callPackage ./bsc/llvm-ompss2/default.nix { };
    clangOmpss2Nanos6 = callPackage ./bsc/llvm-ompss2/default.nix { ompss2rt = final.nanos6; };
    clangOmpss2Nodes = callPackage ./bsc/llvm-ompss2/default.nix { ompss2rt = final.nodes; };
    clangOmpss2Unwrapped = callPackage ./bsc/llvm-ompss2/clang.nix { };
    #extrae = callPackage ./bsc/extrae/default.nix { }; # Broken and outdated
    #gpi-2 = callPackage ./bsc/gpi-2/default.nix { };
    intelPackages_2023 = callPackage ./bsc/intel-oneapi/2023.nix { };
    jemallocNanos6 = callPackage ./bsc/nanos6/jemalloc.nix { };
    #lmbench = callPackage ./bsc/lmbench/default.nix { };
    mcxx = callPackage ./bsc/mcxx/default.nix { };
    nanos6 = callPackage ./bsc/nanos6/default.nix { };
    nanos6Debug = final.nanos6.override { enableDebug = true; };
    #nixtools = callPackage ./bsc/nixtools/default.nix { };
    #nix-wrap = callPackage ./bsc/nix-wrap/default.nix { };
    nodes = callPackage ./bsc/nodes/default.nix { };
    nosv = callPackage ./bsc/nosv/default.nix { };
    osumb = callPackage ./bsc/osu/default.nix { };
    ovni = callPackage ./bsc/ovni/default.nix { };
    ovniGit = final.ovni.override { useGit = true; };
    paraverKernel = callPackage ./bsc/paraver/kernel.nix { };
    #paraverKernelFast = callPackage ./bsc/paraver/kernel-fast.nix { };
    #pscom = callPackage ./bsc/parastation/pscom.nix { };
    #psmpi = callPackage ./bsc/parastation/psmpi.nix { };
    #sonar = callPackage ./bsc/sonar/default.nix { };
    stdenvClangOmpss2Nanos6 = final.stdenv.override { cc = final.clangOmpss2Nanos6; allowedRequisites = null; };
    stdenvClangOmpss2Nodes = final.stdenv.override { cc = final.clangOmpss2Nodes; allowedRequisites = null; };
    #tagaspi = callPackage ./bsc/tagaspi/default.nix { };
    tampi = callPackage ./bsc/tampi/default.nix { };
    wxparaver = callPackage ./bsc/paraver/default.nix { };
    #wxparaverFast = callPackage ./bsc/paraver/wxparaver-fast.nix { };
  };

in bscPkgs // {
  # Prevent accidental usage of bsc attribute
  bsc = throw "the bsc attribute is deprecated, packages are now in the root";

  # Internal for our CI tests
  bsc-ci = {
    test = rec {
      #hwloc = callPackage ./test/bugs/hwloc.nix { };
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
    };

    pkgs = final.runCommand "ci-pkgs" { }
      "printf '%s\n' ${toString (collect isDerivation bscPkgs)} > $out";

    tests = final.runCommand "ci-tests" { }
      "printf '%s\n' ${toString (collect isDerivation final.bsc-ci.test)} > $out";

    all = final.runCommand "ci-all" { }
      "printf '%s\n' ${toString [ final.bsc-ci.pkgs final.bsc-ci.tests ]} > $out";
  };
}
