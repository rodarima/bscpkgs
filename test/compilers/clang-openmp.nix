{ 
  stdenv
, writeText
, openmp
}:

let
  hello_c = writeText "hello.c" ''
  int main(int argc, char *argv[])
  {
    int test = 1;
    #pragma omp parallel
    #pragma omp single
    #pragma omp task
    test = 0;

    return test;
  }
  '';

in stdenv.mkDerivation {
  pname = "openmp-test";
  version = "1.0.0";

  dontUnpack = true;
  dontConfigure = true;

  # nOS-V requires access to /sys/devices to request NUMA information. It will
  # fail to run otherwise, so we disable the sandbox for this test.
  __noChroot = true;

  buildInputs = [ openmp ];

  buildPhase = ''
    set -x

    cp ${hello_c} hello.c
    clang -fopenmp ./hello.c -o hello
    ./hello

    set +x
  '';

  installPhase = ''
    touch $out
  '';

}

