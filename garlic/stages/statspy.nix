{
  stdenv
, bash
}:

{
  program
, outputDir ? "."
}:

stdenv.mkDerivation {
  name = "statspy";
  preferLocalBuild = true;
  phases = [ "installPhase" ];
  programPath = "/bin/${name}";
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/${name} <<EOF
    #!/bin/sh

    mkdir -p ${outputDir}
    cat /proc/[0-9]*/stat | sort -n > ${outputDir}/statspy.\$(date +%s.%3N).begin
    ${program}
    cat /proc/[0-9]*/stat | sort -n > ${outputDir}/statspy.\$(date +%s.%3N).end

    EOF
    chmod +x $out/bin/${name}
  '';
}
