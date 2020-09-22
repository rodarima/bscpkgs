{
  stdenv
}:

{
  program
}:

stdenv.mkDerivation {
  name = "envRecord";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh
    
    >&2 echo ----- ENV BEGIN -------
    >&2 /usr/bin/env
    >&2 echo ----- ENV END -------

    exec ${program} \''${argv[@]}
    EOF
    chmod +x $out
  '';
}
