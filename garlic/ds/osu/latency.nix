{
  stdenv
, python3
, gzip
}:

resultTree:

stdenv.mkDerivation {
  name = "osu-latency.json.gz";
  preferLocalBuild = true;
  src = ./latency.py;
  phases = [ "unpackPhase" "installPhase" ];

  unpackPhase = ''
    cp $src latency.py
  '';

  buildInputs = [ python3 gzip ];
  installPhase = ''
    python latency.py ${resultTree} | gzip > $out
  '';
}
