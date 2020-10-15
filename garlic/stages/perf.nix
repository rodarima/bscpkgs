{
  stdenv
, perf
, garlicTools
}:

{
  nextStage
, perfOptions
}:

with garlicTools;

let
  program = stageProgram nextStage;
in
  stdenv.mkDerivation {
    name = "perf";
    phases = [ "installPhase" ];
    preferLocalBuild = true;
    dontPatchShebangs = true;
    installPhase = ''
      cat > $out <<EOF
      #!/bin/sh
      
      exec ${perf}/bin/perf ${perfOptions} ${program}
      EOF
      chmod +x $out
    '';
  }
