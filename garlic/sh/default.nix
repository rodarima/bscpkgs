{
  stdenv
, garlicTools
, sshHost
, rsync
, openssh
, nix
, jq
, ncurses
}:

with garlicTools;

let
  garlicPrefix = "/mnt/garlic";
in
  stdenv.mkDerivation {
    name = "garlic-tool";
    preferLocalBuild = true;

    buildInputs = [ rsync openssh nix jq ncurses ];
    phases = [ "unpackPhase" "installPhase" ];

    src = ./.;

    inherit garlicPrefix sshHost;

    installPhase = ''
      substituteAllInPlace garlic
      substituteInPlace garlic \
        --replace @PATH@ $PATH
      mkdir -p $out/bin
      cp garlic $out/bin
      chmod +x $out/bin/garlic
      mkdir -p $out/share/man/man1
      cp garlic.1 $out/share/man/man1
      cp garlic-git-table $out/bin
      patchShebangs garlic-propagate-commit
      cp garlic-propagate-commit $out/bin
    '';
  }
