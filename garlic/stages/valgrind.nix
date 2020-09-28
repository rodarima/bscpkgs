{
  stdenv
, bash
, valgrind
}:

{
  program
}:

stdenv.mkDerivation {
  name = "valgrind";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh
    
    exec ${valgrind}/bin/valgrind ${program}
    EOF
    chmod +x $out
  '';
}
