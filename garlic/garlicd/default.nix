{
  stdenv
, nix
, garlicTool
}:

let
  extraPath = "${garlicTool}:${nix}";
in
  stdenv.mkDerivation {
    name = "garlicd";
    preferLocalBuild = true;

    phases = [ "unpackPhase" "installPhase" ];

    src = ./garlicd;

    unpackPhase = ''
      cp $src garlicd
    '';

    installPhase = ''
      substituteInPlace garlicd \
        --replace @extraPath@ ${extraPath}
      mkdir -p $out/bin
      cp -a garlicd $out/bin
    '';
  }
