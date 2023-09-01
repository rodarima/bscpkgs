{ stdenv, writeText, which, strace }:

let
  hello_c = writeText "hello.c" ''
    #include <stdio.h>

    int main()
    {
            printf("Hello world!\n");
            return 0;
    }
  '';
in

stdenv.mkDerivation rec {
  version = "0.0.1";
  name = "asan-c";
  buildInputs = [ stdenv which strace ];
  src = hello_c;
  dontUnpack = true;
  dontConfigure = true;
  NIX_DEBUG = 0;
  buildPhase = ''
    cp ${hello_c} hello.c
    $CC -v -fsanitize=address hello.c -o hello
    ./hello
  '';

  installPhase = ''
    touch $out
  '';
}
