{
  stdenv
}:

{
  program
}:

# This stage provides a clean environment to run experiments
stdenv.mkDerivation {
  name = "broom";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh

    # Removes all environment variables
    /usr/bin/env -i ${program}
    EOF
    chmod +x $out
  '';
}
