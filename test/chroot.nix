{stdenv}:

stdenv.mkDerivation rec {
  version = "0.0.1";
  name = "chroot-checker";
  src = ./chroot.nix;
  dontUnpack = true;
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
    mkdir -p $out
  '';
}
