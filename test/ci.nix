{ self, super, bsc, testPkgs }:

let
  stdenv = self.stdenv;
in

stdenv.mkDerivation rec {
  name = "ci";
  src = ./ci.nix;
  dontUnpack = true;

  # Just build some packages
  buildInputs = testPkgs;

  buildPhase = ''
    if [ -e /boot ]; then
      echo Build is NOT under chroot
      echo This is the content of / :
      ls -l /
      exit 1
    fi

    echo "OK: Build is under chroot"

    echo "buildInputs:"
    printf -- "- %s\n" $buildInputs
  '';

  installPhase = ''
    touch $out
  '';
}
