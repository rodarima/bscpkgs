{
  stdenv
, nixtools
}:

{
  program
, clusterName
}:

stdenv.mkDerivation {
  name = "nix-isolate";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  dontPatchShebangs = true;
  installPhase = ''
    cat > $out <<EOF
    #!/bin/sh -ex

    >&2 echo Running nix-isolate stage
    >&2 echo PATH=$PATH
    >&2 echo Running env:
    env

    # We need to enter the nix namespace first, in order to have /nix
    # available, so we use this hack:
    if [ ! -e /nix ]; then
      exec ${nixtools}/bin/${clusterName}/nix-isolate \$0
    fi

    if [ -e /usr ]; then
      >&2 echo "Environment not isolated, aborting"
      exit 1
    fi

    exec ${program}
    EOF
    chmod +x $out
  '';
}
