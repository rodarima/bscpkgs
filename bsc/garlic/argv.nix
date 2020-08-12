{
  stdenv
}:

{
  app
, argv # bash array as string, example: argv=''(-f "file with spaces" -t 10)''
}:

stdenv.mkDerivation {
  inherit argv;
  name = "${app.name}-argv";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  dontPatchShebangs = true;
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!/bin/sh
    argv=${argv}
    exec ${app}/bin/run \''${argv[@]}
    EOF
    chmod +x $out/bin/run
  '';
}
