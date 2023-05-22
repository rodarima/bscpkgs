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
  #NIX_DEBUG = 1;
  buildInputs = [ strace gdb ];
  # NODES requires access to /sys/devices to request NUMA information. It will
  # fail to run otherwise, so we disable the sandbox for this test.
  __noChroot = true;
  buildPhase = ''
    set -x
    #$CC -v

    cp ${task_c} task.c

    echo CC=$CC
    echo NANOS6_HOME=$NANOS6_HOME
    echo NODES_HOME=$NODES_HOME
    cat task.c
    $CC -fompss-2 task.c -o task
    #strace -ff -e trace=open,openat -s9999999 ./task
    LD_DEBUG=libs ./task
    #gdb -batch -ex "run" -ex "bt" ./task

    set +x
  '';

  installPhase = ''
    touch $out
  '';
}
