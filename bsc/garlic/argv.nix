{
  stdenv
, bash
}:

{
  app
, env ? ""
, argv # bash array as string, example: argv=''(-f "file with spaces" -t 10)''
}:

stdenv.mkDerivation {
  inherit argv;
  name = "${app.name}-argv";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!${bash}/bin/bash
    # Requires /nix to use bash
    
    ${env}

    argv=${argv}
    exec ${app}/bin/run \''${argv[@]}
    EOF
    chmod +x $out/bin/run
  '';
}
