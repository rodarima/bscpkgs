{
  stdenv
}:

{
  script
, shell ? "/bin/sh"
}:

stdenv.mkDerivation {
  name = "script";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  installPhase = ''
    cat > $out <<'EOF'
    #!${shell}

    ${script}

    EOF
    chmod +x $out
  '';
}
