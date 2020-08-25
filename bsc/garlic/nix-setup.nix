{
  stdenv
}:

program:

stdenv.mkDerivation {
  inherit program;
  name = "${program.name}-nixsetup";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  dontPatchShebangs = true;
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!/bin/sh

    # We need to enter the nix namespace first, in order to have /nix
    # available, so we use this hack:
    if [ ! -e /nix ]; then
      exec nix-setup \$0
    fi

    exec $program/bin/run
    EOF
    chmod +x $out/bin/run
  '';
}
