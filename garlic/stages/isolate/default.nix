{
  stdenv
, nixtools
, busybox
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
  src = ./.;
  dontPatchShebangs = true;
  programPath = "/bin/stage1";
  inherit program nixPrefix clusterName nixtools busybox;
  out = "$out";
  installPhase = ''
    substituteAllInPlace stage1
    substituteAllInPlace stage2

    mkdir -p $out/bin
    cp stage* $out/bin/
    chmod +x $out/bin/stage*
  '';
}
