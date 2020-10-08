{
  stdenv
, nixtools
, busybox
, strace
}:

{
  program
, stage
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
  desc = "#  $out\n" + (if builtins.hasAttr "desc" stage then stage.desc else "");
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
