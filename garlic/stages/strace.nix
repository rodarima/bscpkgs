{
  stdenv
, bash
, strace
}:

{
  program
}:

stdenv.mkDerivation {
  name = "strace";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh
    
    exec ${strace}/bin/strace -f ${program}
    EOF
    chmod +x $out
  '';
}
