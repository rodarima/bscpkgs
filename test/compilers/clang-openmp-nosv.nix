{
  stdenv
, nosv
, writeText
, openmp
}:

let
  hello_c = writeText "hello.c" ''
  #include <nosv.h>
  #include <stdlib.h>
  #include <stdio.h>
  int main(int argc, char *argv[])
  {
    int test = 1;
    #pragma omp parallel
    #pragma omp single
    #pragma omp task
    {
        if (nosv_self() == NULL) {
            printf("nosv_self() returned NULL\n");
            exit(1);
        } else {
            printf("nosv_self() INSIDE TASK OK\n");
        }
        test = 0;
    }

    return test;
  }
  '';

in stdenv.mkDerivation {
  pname = "openmp-test-nosv";
  version = "1.0.0";

  dontUnpack = true;
  dontConfigure = true;

  # nOS-V requires access to /sys/devices to request NUMA information. It will
  # fail to run otherwise, so we disable the sandbox for this test.
  __noChroot = true;

  buildInputs = [ nosv openmp ];

  buildPhase = ''
    set -x

    cp ${hello_c} hello.c
    clang -fopenmp=libompv ./hello.c -lnosv -o hello
    ./hello | grep "INSIDE TASK OK"

    set +x
  '';

  installPhase = ''
    touch $out
  '';

}

