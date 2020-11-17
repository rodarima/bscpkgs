{
  stdenv
, fig
}:
stdenv.mkDerivation {
  name = "sedReport";
  src = ./report;
  buildPhase = ''
    grep -o '@[^ @]*@' report.tex | sed 's/@//g' | sort -u > list

    echo "fig:" > fun.nix
    echo "'''" >> fun.nix
    sed 's:\(^.*\)$:sed -i "s;@\1@;''${\1};g" report.tex:g' list >> fun.nix
    echo "'''" >> fun.nix
  '';
  installPhase = ''
    cp fun.nix $out
  '';
}
