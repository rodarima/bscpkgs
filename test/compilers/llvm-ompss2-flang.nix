{
  stdenv
, flangOmpss2Git
, runCommand
, writeText
, strace
}:

stdenv.mkDerivation {
  name = "flang-ompss2-test";
  buildInputs = [ strace flangOmpss2Git ];
  file = writeText "hi.f90"
  ''
          program hello
          print *, 'Hello, World!'
          end program hello
  '';
  phases = [ "installPhase" ];
  installPhase = ''
    set -x
    flang "$file" -c -o hi.o
    flang hi.o -o hi
    install -Dm555 hi "$out"
  '';
}
