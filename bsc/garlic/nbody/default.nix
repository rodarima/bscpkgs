{
  stdenv
, cc
, cflags ? null
, gitBranch
, blocksize ? "2048"
, particles ? "16384"
, timesteps ? "10"
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
    makeFlagsArray+=(CFLAGS=${cflags})
  '' else "");

  makeFlags = [
    "CC=${cc.cc.CC}"
    "BS=${blocksize}"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp nbody $out/bin/

    cat > $out/bin/run <<EOF
    #!/bin/bash
    exec $out/bin/nbody -p ${particles} -t ${timesteps}
    EOF

    chmod +x $out/bin/run
  '';

}
