{
  stdenv
, fig
, writeText
, busybox
, jq
, texlive
}:
let
  # TODO: We can select only which elements we need from fig by using:
  # echo [ $(grep -o '@[^ @]*@' garlic/report.tex | sed 's/@//g') ]
  # and them importing as valid nix lang.

  # By now, we require all plots
  figJSON = writeText "fig.json" (builtins.toJSON fig);
in
  stdenv.mkDerivation {
    name = "report";
    src = ./.;
    buildInputs = [ jq texlive.combined.scheme-basic ];
    buildPhase = ''
      ls -l
      sed -i -e "s:@fig\.nbody\.test@:$(jq -r .nbody.test ${figJSON}):g" report.tex
      jq . ${figJSON}
      pdflatex report.tex -o report.pdf
      # Run again to fix figure references
      pdflatex report.tex -o report.pdf
    '';
    installPhase = ''
      mkdir $out
      cp report.* $out
    '';
  }
