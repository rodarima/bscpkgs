{
  stdenv
, fig
, exp
, writeText
, busybox
, jq
, texlive
}:
let
  figJSON = writeText "fig.json" (builtins.toJSON fig);
  expJSON = writeText "exp.json" (builtins.toJSON exp);
in
  stdenv.mkDerivation {
    name = "report";
    src = ./.;
    buildInputs = [ jq texlive.combined.scheme-basic ];
    buildPhase = ''
      ls -l
      sed -i -e "s:@fig\.nbody\.test@:$(jq -r .nbody.test ${figJSON}):g" report.tex
      jq . ${figJSON}
      jq . ${expJSON}
      pdflatex report.tex -o report.pdf
      pdflatex report.tex -o report.pdf
    '';
    installPhase = ''
      mkdir $out
      cp report.* $out
    '';
  }
