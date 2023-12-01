{
  stdenv
, writeText
, openmp
}:

let
  hello_c = writeText "hello.c" ''
  int main(int argc, char *argv[])
  {
    #pragma omp parallel
    {
    }

    return 0;
  }
  '';

in stdenv.mkDerivation {
  pname = "openmp-test-ld";
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
    clang -fopenmp=libompv ./hello.c -o hello

    set +x
  '';

  installPhase = ''
    touch $out
  '';

}

