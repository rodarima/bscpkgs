{
  stdenv
, bash
}:

{
  program
, env ? ""

# bash array as string, example: argv=''(-f "file with spaces" -t 10)''
, argv ? "()"
}:

stdenv.mkDerivation {
  name = "argv";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<EOF
    #!${bash}/bin/bash
    # Requires /nix to use bash
    
    ${env}

    argv=${argv}
    exec ${program} \''${argv[@]}
    EOF
    chmod +x $out
  '';
}
