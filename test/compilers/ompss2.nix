{ stdenv, writeText, which, strace, gdb }:

let
  task_c = writeText "task.c" ''
    #include <stdio.h>

    int main()
    {
        for (int i = 0; i < 10; i++) {
            #pragma oss task
            printf("Hello world!\n");
        }

        return 0;
    }
  '';
in

stdenv.mkDerivation rec {
  version = "0.0.1";
  name = "task_c";
  src = task_c;
  dontUnpack = true;
  dontConfigure = true;
  hardeningDisable = [ "all" ];
  NIX_DEBUG = 1;
  buildInputs = [ strace gdb ];
  __noChroot = true; # Required for NODES
  buildPhase = ''
    set -x
    echo CC=$CC
    $CC -v

    cp ${task_c} task.c
    cat task.c
    $CC -v -fompss-2 task.c -o task
    #strace -ff -e trace=open,openat -s9999999 ./task
    LD_DEBUG=libs ./task
    #gdb -batch -ex "run" -ex "bt" ./task

    set +x
  '';

  installPhase = ''
    touch $out
  '';
}
