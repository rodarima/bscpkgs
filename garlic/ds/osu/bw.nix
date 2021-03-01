{
  stdenv
, python3
, gzip
}:

resultTree:

stdenv.mkDerivation {
  name = "osu-bw.json.gz";
  preferLocalBuild = true;
  src = ./bw.py;
  phases = [ "unpackPhase" "installPhase" ];

  unpackPhase = ''
    cp $src bw.py
  '';

  buildInputs = [ python3 gzip ];
  installPhase = ''
    python bw.py ${resultTree} | gzip > $out
  '';
}
