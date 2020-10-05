{
  stdenv
, nixtools
, busybox
, strace
}:

{
  program
, nixPrefix
, clusterName
}:

stdenv.mkDerivation {
  name = "isolate";
  preferLocalBuild = true;
  phases = [ "unpackPhase" "installPhase" ];
  buildInputs = [
    #nixtools
    #strace
  ];
  src = ./.;
  dontPatchShebangs = true;
  programPath = "/bin/stage1";
  inherit program nixPrefix clusterName nixtools busybox;
  out = "$out";
  installPhase = ''

    echo PATH=$PATH

    substituteAllInPlace stage1
    substituteAllInPlace stage2

    sed -i "s|@extraPath@|$PATH|g" stage1

    mkdir -p $out/bin
    cp stage* $out/bin/
    chmod +x $out/bin/stage*
  '';
}
