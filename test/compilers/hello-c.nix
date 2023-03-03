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
  shuffle_c = writeText "shuffle.c" ''
    #include <stdio.h>

    typedef int v4si __attribute__ ((vector_size (16)));

    int main(void) {
	 v4si a = {1,2,3,4};
	 v4si b = {5,6,7,8};
	 v4si mask1 = {0,1,1,3};
	 v4si mask2 = {0,4,2,5};
	 v4si res;

    #if defined(__GNUC__) && (__GNUC__ >= 7)
	 res = __builtin_shuffle (a, mask1);       /* res is {1,2,2,4}  */
	 res = __builtin_shuffle (a, b, mask2);    /* res is {1,5,3,6}  */

	 printf("%d %d %d %d\n", res[0], res[1], res[2], res[3]);
    #endif

	 return 0;
    }
  '';
in

stdenv.mkDerivation rec {
  version = "0.0.1";
  name = "hello-c";
  buildInputs = [ stdenv which strace ];
  src = hello_c;
  dontUnpack = true;
  dontConfigure = true;
  NIX_DEBUG = 0;
  buildPhase = ''
    set -x
    echo CC=$CC
    which $CC
    $CC -v

    cp ${hello_c} hello.c
    $CC -v hello.c -o hello
    ./hello

    # Only gcc
    #cp ${shuffle_c} shuffle.c
    #$CC shuffle.c -o shuffle
    #./shuffle

    set +x
  '';

  installPhase = ''
    touch $out
  '';
}
