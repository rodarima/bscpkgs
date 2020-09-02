{
  stdenv
}:

{
  program
}:

stdenv.mkDerivation {
  name = "nixsetup";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  dontPatchShebangs = true;
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh

    # We need to enter the nix namespace first, in order to have /nix
    # available, so we use this hack:
    if [ ! -e /nix ]; then
      exec nix-setup \$0
    fi

    exec ${program}
    EOF
    chmod +x $out
  '';
}
