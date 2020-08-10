{
  stdenv
, cc
, cflags ? null
, gitBranch
, blocksize ? 2048
, particles ? 16384
, timesteps ? 10
}:

stdenv.mkDerivation {
  name = "nbody";

  src = builtins.fetchGit {
    url = "ssh://git@bscpm02.bsc.es/rarias/nbody.git";
    ref = gitBranch;
  };

  buildInputs = [
    cc
  ];

  preBuild = (if cflags != null then ''
    makeFlagsArray+=(CFLAGS="${cflags}")
  '' else "");

  makeFlags = [
    "CC=${cc.cc.CC}"
    "BS=${toString blocksize}"
  ];

  dontPatchShebangs = true;

  installPhase = ''
    mkdir -p $out/bin
    cp nbody $out/bin/

    cat > $out/bin/run <<EOF
    #!/bin/sh

    # We need to enter the nix namespace first, in order to have /nix
    # available, so we use this hack:
    if [ ! -e /nix ]; then
      echo "running nix-setup \$0"
      exec nix-setup \$0
    fi

    ls -l /nix
    pwd

    exec $out/bin/nbody -p ${toString particles} -t ${toString timesteps}
    EOF

    chmod +x $out/bin/run
  '';

}
