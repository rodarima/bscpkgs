{ stdenv, writeText, which, strace }:

let
  hello_f90 = writeText "hello.f90" ''
    program hello
      print *, 'Hello, World!'
    end program hello
  '';
in

stdenv.mkDerivation rec {
  version = "0.0.1";
  name = "hello-f90";
  buildInputs = [ stdenv which strace ];
  src = hello_f90;
  dontUnpack = true;
  dontConfigure = true;
  NIX_DEBUG = 0;
  buildPhase = ''
    set -x
    echo FC=$FC
    which $FC
    $FC -v

    cp ${hello_f90} hello.f90
    $FC hello.f90 -o hello
    ./hello

    set +x
  '';

  installPhase = ''
    touch $out
  '';
}
