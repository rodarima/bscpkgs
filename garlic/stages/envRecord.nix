{
  stdenv
}:

{
  program
}:

stdenv.mkDerivation {
  name = "argv";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh
    
    echo ----- ENV BEGIN -------
    /usr/bin/env
    echo ----- ENV END -------

    exec ${program} \''${argv[@]}
    EOF
    chmod +x $out
  '';
}
