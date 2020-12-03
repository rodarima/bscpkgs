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

    curdir="\$(pwd)"
    export "buildInputs=$buildInputs"
    # ${stdenv}
    export "PATH=$PATH"
    export "out=/fake-output-directory"
    export NIX_BUILD_TOP=.
    export NIX_STORE=/nix/store
    export PS1='\[\033[1;32m\]develop\$\[\033[0m\] '

    export TMUX_TMPDIR=/tmp
    export TMPDIR=/tmp
    export TEMPDIR=/tmp
    export TMP=/tmp
    export TEMP=/tmp

    export LANG=en_US.UTF-8

    source ${stdenv}/setup

    # Access to bin and nix tools for srun, as it keeps the PATH
    export "PATH=\$PATH:/bin"
    export "PATH=$PATH:/gpfs/projects/bsc15/nix/bin"
    export "SHELL=${bashInteractive}/bin/bash"
    export HISTFILE="\$curdir/.histfile"

    if [[ -z "\$@" ]]; then
      exec ${bashInteractive}/bin/bash
    else
      exec "\$@"
    fi
    EOF
    chmod +x $out
  '';
}
