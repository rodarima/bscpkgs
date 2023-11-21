{stdenv, clang-ompss2, nanos6}:

stdenv.mkDerivation rec {
  version = "0.0.1";
  name = "test-clang-ompss2";
  src = ./.;
  buildInputs = [ clang-ompss2 nanos6 ];
  NIX_DEBUG = 1;

  buildPhase = ''
    clang -fompss-2 hello.c -o hello
    ./hello
    clang++ -fompss-2 hello.cc -o hello
    ./hello
  '';

  installPhase = ''
    mkdir -p $out
  '';
}
