{ self, super, bsc, callPackage }:

let
  stdenv = self.stdenv;
in

stdenv.mkDerivation rec {
  name = "ci";
  src = ./ci.nix;
  dontUnpack = true;

  # Just build some packages
  buildInputs = with bsc; [
    # Compilers
    icc
    clangOmpss2
    mcxx
    # MPI
    impi
    mpich
    openmpi
    tampi
    # Tools
    ovni
    extrae
    wxparaver
    # Runtimes
    nanos6
  ];

  buildPhase = ''
    if [ -e /boot ]; then
      echo Build is NOT under chroot
      echo This is the content of / :
      ls -l /
      exit 1
    fi

    echo "OK: Build is under chroot"
  '';

  installPhase = ''
    touch $out
  '';
}
