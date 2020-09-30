{
  stdenv
, bash
, screen
, gdb
}:

{
  program
, gdbArgs ? "-ex run"
}:

stdenv.mkDerivation {
  name = "pgdb";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh
    
    exec ${screen}/bin/screen -D -m \
      ${gdb}/bin/gdb \
      -ex 'set pagination off' \
      ${gdbArgs} \
      --args ${program} \$@

    EOF
    chmod +x $out
  '';
}
