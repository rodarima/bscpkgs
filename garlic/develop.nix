{
  stdenv
, bash
, bashInteractive
, busybox
, extraInputs  ? []
}:

stdenv.mkDerivation {
  name = "develop";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  buildInputs = extraInputs ++ [ busybox ];
  installPhase = ''
    cat > $out <<EOF
    #!${bash}/bin/bash

    # This program loads a environment with the given programs available.
    # Requires /nix to be available.

    export "buildInputs=$buildInputs"
    # ${stdenv}
    export "PATH=$PATH"
    export "TERM=linux"
    export "out=/fake-output-directory"
    export NIX_BUILD_TOP=.
    export NIX_STORE=/nix/store
    export PS1='\033[1;32mdevelop\$\033[0m '
    #export PS1='\[\033[1;32m\]develop\$\[\033[0m\] '

    export TMUX_TMPDIR=/tmp
    export TMPDIR=/tmp
    export TEMPDIR=/tmp
    export TMP=/tmp
    export TEMP=/tmp

    export LANG=en_US.UTF-8
    export TERM=linux

    source ${stdenv}/setup

    if [[ -z "\$@" ]]; then
      exec ${bashInteractive}/bin/bash
    else
      exec "\$@"
    fi
    EOF
    chmod +x $out
  '';
}
