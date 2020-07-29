{
  stdenv
, app
, argv ? ""
, binary ? "/bin/run"
}:

stdenv.mkDerivation {
  name = "${app.name}-runner";
  preferLocalBuild = true;

  src = ./.;

  buildInputs = [ app ];

  installPhase = ''
    mkdir -p $out/bin

    cat > $out/bin/run <<EOF
    #!/bin/bash
    exec ${app}${binary} ${argv}
    done
    EOF

    chmod +x $out/bin/run
  '';
}
