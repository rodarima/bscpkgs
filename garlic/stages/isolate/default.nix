{
  stdenv
, nixtools
, busybox
, garlicTools
}:

{
  nextStage
, nixPrefix
, clusterName ? "mn4"
}:

with garlicTools;

stdenv.mkDerivation {
  name = "isolate";
  preferLocalBuild = true;
  phases = [ "unpackPhase" "installPhase" ];
  src = ./.;
  dontPatchShebangs = true;
  programPath = "/bin/stage1";
  inherit nixPrefix clusterName nixtools busybox;
  inherit nextStage;
  program = stageProgram nextStage;
  desc = "#  $out\n" + (if builtins.hasAttr "desc" nextStage then nextStage.desc else "");
  out = "$out";
  installPhase = ''
    substituteAllInPlace stage1
    substituteAllInPlace stage2

    sed -i "s|@extraPath@|$PATH|g" stage1

    mkdir -p $out/bin
    cp stage* $out/bin/
    chmod +x $out/bin/stage*
  '';
}