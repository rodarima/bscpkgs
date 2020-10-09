{
  stdenv
, strace
, garlicTools
}:

{
  nextStage
}:

with garlicTools;

let
  program = stageProgram nextStage;
in
  stdenv.mkDerivation {
    name = "strace";
    phases = [ "installPhase" ];
    preferLocalBuild = true;
    dontPatchShebangs = true;
    installPhase = ''
      cat > $out <<EOF
      #!/bin/sh
      
      exec ${strace}/bin/strace -f ${program}
      EOF
      chmod +x $out
    '';
  }
