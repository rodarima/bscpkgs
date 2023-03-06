{ stdenv, writeText, which, strace }:

let
  hello_c = writeText "hello.c" ''
    #include <stdio.h>
    #include <limits.h>
    #include <xmmintrin.h>

    int main()
    {
            printf("Hello world!\n");
            return 0;
    }
  '';
in

stdenv.mkDerivation rec {
  version = "0.0.1";
  name = "lto-c";
  buildInputs = [ stdenv which strace ];
  src = hello_c;
  dontUnpack = true;
  dontConfigure = true;
  NIX_DEBUG = 0;
  buildPhase = ''
    set -x
    echo CC=$CC
    echo LD=$LD
    echo -------------------------------------------
    env
    echo -------------------------------------------

    cp ${hello_c} hello.c
    $CC -v -flto hello.c -o hello
    ./hello

    set +x
  '';

  installPhase = ''
    touch $out
  '';
}
