{
  stdenv
, ministat
}:

stdenv.mkDerivation {
  name = "hist";
  preferLocalBuild = true;
  src = ./.;

  dontBuild = true;
  dontConfigure = true;

  inherit ministat;

  patchPhase = ''
    substituteAllInPlace hist.sh 
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp hist.sh $out/bin/hist
    chmod +x $out/bin/hist
  '';
}
