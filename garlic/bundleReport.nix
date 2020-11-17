{
  stdenv
, fig
}:

stdenv.mkDerivation {
  name = "report.tar.gz";
  src = ./report;
  buildPhase = ''
    pwd
    ls -l
    grep -o '@[^ @]*@' report.tex | sed 's/@//g' | sort -u > list

    echo "fig:" > fun.nix
    echo "'''" >> fun.nix
    for line in $(cat list); do
      localPath=$(echo $line | tr '.' '/')
      echo "mkdir -p $localPath" >> fun.nix
      echo "cp -r \''${$line}/* $localPath" >> fun.nix
      echo "sed -i 's;@$line@;$localPath;g' report.tex" >> fun.nix
    done
    echo "'''" >> fun.nix

    echo " ---------- this is the fun.nix -------------"
    cat fun.nix
    echo " --------------------------------------------"
  '';
  installPhase = ''
    cp fun.nix $out
  '';
}
