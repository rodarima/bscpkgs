{
  stdenv
, mpi
}:

stdenv.mkDerivation {
  name = "sigsegv";

  src = ./.;

  buildInputs = [ mpi ];

  buildPhase = ''
    mpicc sigsegv.c -o sigsegv
  '';

  installPhase = ''
    cp sigsegv $out
  '';
}
