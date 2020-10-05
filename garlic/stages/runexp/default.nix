{
  stdenv
, nixtools
}:

{
  program
, nixPrefix
, sshHost ? "mn"
, targetCluster ? "mn4"
}:

stdenv.mkDerivation {
  name = "runexp";
  preferLocalBuild = true;
  phases = [ "unpackPhase" "installPhase" ];
  dontPatchShebangs = true;
  src = ./.;
  inherit sshHost nixPrefix nixtools targetCluster program;
  installPhase = ''
    substituteAllInPlace runexp
    cp runexp $out
    chmod +x $out
  '';
}
