{ stdenv, writeText, which, strace }:

let
  hello_cpp = writeText "hello.cpp" ''
    #include <cstdio>

    int main()
    {
            printf("Hello world!\n");
            return 0;
    }
  '';
in

stdenv.mkDerivation rec {
  version = "0.0.1";
  name = "hello-cpp";
  buildInputs = [ stdenv which strace ];
  src = hello_cpp;
  dontUnpack = true;
  dontConfigure = true;
  NIX_DEBUG = 0;
  buildPhase = ''
    cp $src hello.cpp
    set -x
    echo CXX=$CXX
    which $CXX
    $CXX hello.cpp -o hello
    ./hello
    set +x
  '';

  installPhase = ''
    touch $out
  '';
}
