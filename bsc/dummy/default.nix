{
  stdenv
}:

stdenv.mkDerivation rec {
  name = "dummy";

  src = null;
  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin

    cat > $out/bin/dummy <<EOF
    #!/bin/sh
    echo Hello world!
    EOF

    chmod +x $out/bin/dummy
  '';
}
