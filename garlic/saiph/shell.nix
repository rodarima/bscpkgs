with (import ../../default.nix);
with bsc;

stdenv.mkDerivation rec {
  name = "shell";
  buildInputs = [
    clangOmpss2
    impi
    nanos6
    tampi
    vtk
    boost
  ];
}
