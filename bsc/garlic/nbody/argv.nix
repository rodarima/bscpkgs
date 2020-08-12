{
  stdenv
, particles
, timestamps
, program
, config
}:

stdenv.mkDerivation {
  inherit program;

  passthru = {
    inherit config;
  };

  name = "${program.name}-argv";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  dontPatchShebangs = true;
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/run <<EOF
    #!/bin/sh
    exec ${program}/bin/run -p ${toString config.particles} -t ${toString config.timesteps}
    EOF

    chmod +x $out/bin/run
  '';
}
