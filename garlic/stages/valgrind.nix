{
  stdenv
, valgrind
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
    name = "valgrind";
    phases = [ "installPhase" ];
    preferLocalBuild = true;
    dontPatchShebangs = true;
    installPhase = ''
      cat > $out <<EOF
      #!/bin/sh
      
      exec ${valgrind}/bin/valgrind ${program}
      EOF
      chmod +x $out
    '';
  }
