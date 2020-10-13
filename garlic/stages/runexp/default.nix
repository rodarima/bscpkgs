{
  stdenv
, garlicTools
}:

{
  nextStage
, nixPrefix
}:

with garlicTools;

stdenv.mkDerivation {
  name = "runexp";
  preferLocalBuild = true;
  phases = [ "unpackPhase" "installPhase" ];
  src = ./.;
  dontPatchShebangs = true;
  programPath = "/bin/runexp";
  inherit nixPrefix nextStage;
  program = stageProgram nextStage;
  installPhase = ''
    substituteAllInPlace runexp

    mkdir -p $out/bin
    cp runexp $out/bin/
    chmod +x $out/bin/runexp
  '';
}
