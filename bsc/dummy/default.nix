{
  stdenv
}:

stdenv.mkDerivation rec {
  name = "dummy";

  src = null;
  dontUnpack = true;
  dontBuild = true;

  programPath = "/bin/dummy";

  installPhase = ''
    mkdir -p $out/bin

    cat > $out/bin/dummy <<EOF
    #!/bin/sh
    echo Hello worlda!

    EOF

    chmod +x $out/bin/dummy
  '';
}
