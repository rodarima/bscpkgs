{
  stdenv
}:

{
  script
, shell ? "/bin/sh"
, exitOnError ? true
}:

let
  setcmd = if exitOnError then "set -e" else "";
in
stdenv.mkDerivation {
  name = "script";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<'EOF'
    #!${shell}
    ${setcmd}

    ${script}

    EOF
    chmod +x $out
  '';
}
