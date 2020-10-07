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
  name = "trebuchet";
  preferLocalBuild = true;
  phases = [ "unpackPhase" "installPhase" ];
  dontPatchShebangs = true;
  src = ./.;
  inherit sshHost nixPrefix nixtools targetCluster program;
  installPhase = ''
    substituteAllInPlace trebuchet
    cp trebuchet $out
    chmod +x $out
  '';
}
