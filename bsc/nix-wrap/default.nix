{
  stdenv
, bashInteractive
, busybox
, nix
, writeText
, pkgsStatic
}:

let
  bubblewrap = pkgsStatic.bubblewrap;
  nixPrefix = "/gpfs/projects/bsc15/nix";
  nixConfDir = "share";
  nix_wrap_sh = writeText "nix-wrap.sh" ''
    #!/usr/bin/env bash
    #
    busybox_bin="${nixPrefix}${busybox}/bin"
    bubblewrap_bin="${nixPrefix}/${bubblewrap}/bin"

    bashInteractive_bin="${bashInteractive}/bin"
    nix_bin="${nix}/bin"
    
    rootdir=$(mktemp -d)
    tmpdir=$(mktemp -d)
    
    args=(
      --bind "$rootdir/" /
      --bind "${nixPrefix}/nix" /nix
      --bind "$busybox_bin" /bin
      --dev-bind /dev /dev
      --bind /boot /boot
      --proc /proc
      --bind /run /run
      --bind /sys /sys
      --bind "$tmpdir" /tmp
      --bind "$PWD" "$PWD"
      --bind /etc/host.conf /etc/host.conf
      --bind /etc/hosts /etc/hosts
      --bind /etc/networks /etc/networks
      --bind /etc/passwd /etc/passwd
      --bind /etc/group /etc/group
      --bind /etc/nsswitch.conf /etc/nsswitch.conf
      --bind /etc/resolv.conf /etc/resolv.conf
    )
    
    export PATH="/bin:$bashInteractive_bin"
    export PATH="$nix_bin:$PATH"
    export TMPDIR=/tmp
    export PS1="[nix-wrap] \u@\h \W $ "
    export NIX_CONF_DIR=@out@/share

    if [ $# -eq 0 ]; then
      "$bubblewrap_bin/bwrap" ''${args[@]} /bin/sh
    else
      "$bubblewrap_bin/bwrap" ''${args[@]} "''${@}"
    fi
    
  '';
  nix_conf = writeText "nix.conf" ''
    experimental-features = nix-command flakes
    sandbox-fallback = false
  '';

in

stdenv.mkDerivation rec {
  version = "0.0.1";
  name = "nix-wrap";
  buildInputs = [
    bashInteractive
    busybox
    nix
  ];
  src = null;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  NIX_DEBUG = 0;

  installPhase = ''
    mkdir -p $out/bin
    substituteAll ${nix_wrap_sh} $out/bin/nix-wrap
    chmod +x $out/bin/nix-wrap

    mkdir -p $out/share
    cp ${nix_conf} $out/share/nix.conf
  '';
}

