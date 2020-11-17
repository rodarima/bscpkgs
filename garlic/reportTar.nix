{
  stdenv
, fig
, writeText
, busybox
, jq
, texlive
, bundleReport
}:
let

  genCmd = (import bundleReport) fig;
in
  stdenv.mkDerivation {
    name = "report.tar.gz";
    src = ./report;
    buildInputs = [ jq texlive.combined.scheme-basic ];
    buildPhase = ''
      ${genCmd}
      ls -ltR
      cat report.tex
      make
    '';
    installPhase = ''
      cd ..
      tar -czf $out report
    '';
  }
