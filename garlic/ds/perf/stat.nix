{
  stdenv
, python3
, gzip
}:

resultTree:

stdenv.mkDerivation {
  name = "perf-stat.json.gz";
  preferLocalBuild = true;
  src = ./stat.py;
  phases = [ "unpackPhase" "installPhase" ];

  unpackPhase = ''
    cp $src stat.py
  '';

  buildInputs = [ python3 gzip ];
  installPhase = ''
    python stat.py ${resultTree} | gzip > $out
  '';
}
