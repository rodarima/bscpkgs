{
  stdenv
, fig
, writeText
, busybox
, jq
, texlive
, sedReport
}:
let
  # TODO: We can select only which elements we need from fig by using:
  # echo [ $(grep -o '@[^ @]*@' garlic/report.tex | sed 's/@//g') ]
  # and them importing as valid nix lang.

  # By now, we require all plots
  figJSON = writeText "fig.json" (builtins.toJSON fig);
  sedCmd = (import sedReport) fig;
in
  stdenv.mkDerivation {
    name = "report";
    src = ./.;
    buildInputs = [ jq texlive.combined.scheme-basic ];
    buildPhase = ''
      ${sedCmd}
      cat report.tex
      pdflatex report.tex -o report.pdf
      # Run again to fix figure references
      pdflatex report.tex -o report.pdf
    '';
    installPhase = ''
      mkdir $out
      cp report.* $out
    '';
  }
