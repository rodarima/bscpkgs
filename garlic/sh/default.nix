{
  stdenv
, garlicTools
, sshHost
, rsync
, openssh
, nix
}:

with garlicTools;

let
  garlicPrefix = "/mnt/garlic";
  garlicTemp = "/tmp/garlic";
in
  stdenv.mkDerivation {
    name = "garlic-tool";
    preferLocalBuild = true;

    buildInputs = [ rsync openssh nix ];
    phases = [ "unpackPhase" "installPhase" ];

    src = ./.;

    inherit garlicPrefix garlicTemp sshHost;

    installPhase = ''
      substituteAllInPlace garlic
      substituteInPlace garlic \
        --replace @PATH@ $PATH
      mkdir -p $out/bin
      cp garlic $out/bin
      chmod +x $out/bin/garlic
    '';
  }
